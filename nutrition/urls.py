from django.urls import path
from .views import (
    PantryView, PantryItemView, DietPlanListView, CreateDietPlanView,
    AssignDietView, UpdateDietPlanView, UpdateMealView, RecruitScheduleView
)

urlpatterns = [
    path('pantry/', PantryView.as_view(), name='pantry'),
    path('pantry/<int:pk>/', PantryItemView.as_view(), name='pantry-item'),
    path('plans/', DietPlanListView.as_view(), name='diet-plans'),
    path('create/', CreateDietPlanView.as_view(), name='create-diet'),
    path('assign/', AssignDietView.as_view(), name='assign-diet'),
    path('plan/<int:pk>/', UpdateDietPlanView.as_view(), name='plan-detail'),

    # NEW URLS
    path('meal/<int:pk>/update/', UpdateMealView.as_view(), name='update-meal'),
    path('schedule/<int:recruit_id>/', RecruitScheduleView.as_view(), name='recruit-schedule'),
]