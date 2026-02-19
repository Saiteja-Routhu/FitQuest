from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import transaction
from .models import FoodItem, DietPlan, Meal, MealItem, Supplement, DietSchedule
from .serializers import FoodItemSerializer, DietPlanSerializer, DietScheduleSerializer


# 1. PANTRY (List & Create)
class PantryView(generics.ListCreateAPIView):
    serializer_class = FoodItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return FoodItem.objects.filter(coach=self.request.user)

    def perform_create(self, serializer):
        serializer.save(coach=self.request.user)


# 2. PANTRY ITEM (Delete)
class PantryItemView(generics.DestroyAPIView):
    queryset = FoodItem.objects.all()
    serializer_class = FoodItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return FoodItem.objects.filter(coach=self.request.user)


# 3. DIET PLANS (List)
class DietPlanListView(generics.ListAPIView):
    serializer_class = DietPlanSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return DietPlan.objects.filter(coach=self.request.user)


# 4. CREATE FULL PLAN
class CreateDietPlanView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        data = request.data
        try:
            with transaction.atomic():
                # A. Create Plan
                plan = DietPlan.objects.create(
                    coach=request.user,
                    name=data['name'],
                    description=data.get('description', ''),
                    water_target_liters=data.get('water_target', 3.0)
                )

                # B. Add Supplements
                for supp in data.get('supplements', []):
                    Supplement.objects.create(plan=plan, name=supp['name'], dosage=supp['dosage'])

                # C. Add Meals & Items
                total_cals, total_prot, total_carbs, total_fats = 0, 0, 0, 0

                for meal_data in data.get('meals', []):
                    meal = Meal.objects.create(plan=plan, name=meal_data['name'], order=meal_data.get('order', 1))

                    for item in meal_data.get('items', []):
                        food = FoodItem.objects.get(id=item['food_id'])
                        qty = float(item['quantity'])
                        MealItem.objects.create(meal=meal, food_item=food, quantity=qty)

                        total_cals += food.calories * qty
                        total_prot += food.protein * qty
                        total_carbs += food.carbs * qty
                        total_fats += food.fats * qty

                # D. Update Totals
                plan.total_calories = round(total_cals)
                plan.total_protein = round(total_prot)
                plan.total_carbs = round(total_carbs)
                plan.total_fats = round(total_fats)
                plan.save()

                return Response({"message": "Diet Plan Created", "id": plan.id}, status=201)
        except Exception as e:
            return Response({"error": str(e)}, status=400)


# 5. ASSIGN PLAN (Bulk Assign)
class AssignDietView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        plan_id = request.data.get('plan_id')
        recruit_ids = request.data.get('recruit_ids')

        try:
            plan = DietPlan.objects.get(id=plan_id, coach=request.user)
            recruits = plan.coach.recruits.filter(id__in=recruit_ids)
            plan.assigned_to.add(*recruits)
            return Response({"message": f"Assigned to {recruits.count()} recruits."})
        except DietPlan.DoesNotExist:
            return Response({"error": "Plan not found"}, status=404)


# 6. UPDATE DIET PLAN (General Info)
class UpdateDietPlanView(generics.RetrieveUpdateDestroyAPIView):
    queryset = DietPlan.objects.all()
    serializer_class = DietPlanSerializer
    permission_classes = [permissions.IsAuthenticated]


# 7. UPDATE SINGLE MEAL (New Feature)
class UpdateMealView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            meal = Meal.objects.get(id=pk, plan__coach=request.user)

            # 1. Clear old items
            meal.items.all().delete()

            # 2. Add new items
            total_cals, total_prot, total_carbs, total_fats = 0, 0, 0, 0

            for item_data in request.data.get('items', []):
                food = FoodItem.objects.get(id=item_data['food_id'])
                qty = float(item_data['quantity'])
                MealItem.objects.create(meal=meal, food_item=food, quantity=qty)

                # Sum for Meal totals (optional, but good for plan recalc)
                total_cals += food.calories * qty
                total_prot += food.protein * qty
                total_carbs += food.carbs * qty
                total_fats += food.fats * qty

            # 3. Recalculate PLAN totals
            plan = meal.plan
            # Reset plan totals to 0 and sum up ALL meals
            p_cals, p_prot, p_carbs, p_fats = 0, 0, 0, 0
            for m in plan.meals.all():
                for i in m.items.all():
                    p_cals += i.food_item.calories * i.quantity
                    p_prot += i.food_item.protein * i.quantity
                    p_carbs += i.food_item.carbs * i.quantity
                    p_fats += i.food_item.fats * i.quantity

            plan.total_calories = round(p_cals)
            plan.total_protein = round(p_prot)
            plan.total_carbs = round(p_carbs)
            plan.total_fats = round(p_fats)
            plan.save()

            return Response({"message": "Meal updated", "plan_totals": plan.total_calories})
        except Exception as e:
            return Response({"error": str(e)}, status=400)


# 8. MANAGE WEEKLY SCHEDULE (New Feature)
class RecruitScheduleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, recruit_id):
        schedules = DietSchedule.objects.filter(recruit_id=recruit_id)
        serializer = DietScheduleSerializer(schedules, many=True)
        return Response(serializer.data)

    def post(self, request, recruit_id):
        # Expects: {"day": "Monday", "plan_id": 5}
        day = request.data.get('day')
        plan_id = request.data.get('plan_id')

        schedule, created = DietSchedule.objects.get_or_create(
            recruit_id=recruit_id,
            day_of_week=day,
            defaults={'coach': request.user}
        )
        if plan_id:
            schedule.diet_plan_id = plan_id
            schedule.save()
        else:
            schedule.delete()  # Remove plan from that day

        return Response({"message": "Schedule updated"})