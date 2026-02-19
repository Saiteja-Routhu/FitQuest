from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Exercise, WorkoutPlan
from .serializers import ExerciseSerializer, WorkoutPlanSerializer

# 1. List all Exercises (DISABLE PAGINATION so App gets all 150+)
class ExerciseListView(generics.ListAPIView):
    queryset = Exercise.objects.all()
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None  # 👈 THIS FIXES THE "ONLY 10" BUG

# 2. Create a Workout Plan
class CreateWorkoutView(generics.CreateAPIView):
    queryset = WorkoutPlan.objects.all()
    serializer_class = WorkoutPlanSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(coach=self.request.user)

# 3. Assign Plan
class AssignPlanView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        plan_id = request.data.get('plan_id')
        recruit_ids = request.data.get('recruit_ids')

        try:
            plan = WorkoutPlan.objects.get(id=plan_id, coach=request.user)
            if isinstance(recruit_ids, list):
                plan.assigned_to.add(*recruit_ids)
            else:
                plan.assigned_to.add(recruit_ids)
            return Response({"message": "Plan assigned successfully"})
        except WorkoutPlan.DoesNotExist:
            return Response({"error": "Plan not found or not yours"}, status=404)

# 4. Get Coach's Plans (DISABLE PAGINATION so App gets the list)
class CoachPlansView(generics.ListAPIView):
    serializer_class = WorkoutPlanSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None # 👈 THIS FIXES THE "EMPTY LIST" BUG

    def get_queryset(self):
        return WorkoutPlan.objects.filter(coach=self.request.user).order_by('-created_at')