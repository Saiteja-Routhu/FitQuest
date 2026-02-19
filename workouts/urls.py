from django.urls import path
from .views import ExerciseListView, CreateWorkoutView, AssignPlanView, CoachPlansView

urlpatterns = [
    path('exercises/', ExerciseListView.as_view(), name='exercise-list'),
    path('create/', CreateWorkoutView.as_view(), name='create-plan'),
    path('assign/', AssignPlanView.as_view(), name='assign-plan'),
    path('my-plans/', CoachPlansView.as_view(), name='my-plans'),
]