from rest_framework import serializers
from .models import FoodItem, DietPlan, Meal, MealItem, Supplement, DietSchedule  # 👈 DietSchedule Imported
from users.serializers import UserSerializer


class FoodItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodItem
        fields = '__all__'
        read_only_fields = ['coach']


class MealItemSerializer(serializers.ModelSerializer):
    food_details = FoodItemSerializer(source='food_item', read_only=True)
    food_id = serializers.PrimaryKeyRelatedField(
        queryset=FoodItem.objects.all(), source='food_item', write_only=True
    )

    class Meta:
        model = MealItem
        fields = ['id', 'meal', 'food_id', 'food_details', 'quantity']


class MealSerializer(serializers.ModelSerializer):
    items = MealItemSerializer(many=True, read_only=True)

    class Meta:
        model = Meal
        fields = ['id', 'plan', 'name', 'order', 'items']


class SupplementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplement
        fields = ['id', 'plan', 'name', 'dosage', 'notes']


class DietPlanSerializer(serializers.ModelSerializer):
    meals = MealSerializer(many=True, read_only=True)
    supplements = SupplementSerializer(many=True, read_only=True)
    assigned_recruits = UserSerializer(source='assigned_to', many=True, read_only=True)

    class Meta:
        model = DietPlan
        fields = [
            'id', 'name', 'description', 'water_target_liters',
            'total_calories', 'total_protein', 'total_carbs', 'total_fats',
            'meals', 'supplements', 'assigned_recruits', 'created_at'
        ]


# 6. SCHEDULE SERIALIZER (NEW)
class DietScheduleSerializer(serializers.ModelSerializer):
    diet_plan_details = DietPlanSerializer(source='diet_plan', read_only=True)

    class Meta:
        model = DietSchedule
        fields = ['id', 'day_of_week', 'diet_plan', 'diet_plan_details']