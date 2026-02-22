from django.urls import path
from .views import ExerciseListView, CreateWorkoutView, AssignPlanView, CoachPlansView, UpdateDeleteWorkoutPlanView, RecruitAssignedPlansView

urlpatterns = [
    path('exercises/', ExerciseListView.as_view(), name='exercise-list'),
    path('create/', CreateWorkoutView.as_view(), name='create-plan'),
    path('assign/', AssignPlanView.as_view(), name='assign-plan'),
    path('my-plans/', CoachPlansView.as_view(), name='my-plans'),
    path('plans/<int:pk>/', UpdateDeleteWorkoutPlanView.as_view(), name='update-delete-plan'),
    path('assigned/', RecruitAssignedPlansView.as_view(), name='recruit-assigned-plans'),
]