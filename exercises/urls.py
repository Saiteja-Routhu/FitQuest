from django.urls import path
from . import views

urlpatterns = [
    path('', views.get_all_exercises, name='get_all_exercises'), # /api/exercises/
    path('<int:exercise_id>/', views.get_exercise_detail, name='get_exercise_detail'), # /api/exercises/1/
]