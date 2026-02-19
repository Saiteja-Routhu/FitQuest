from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import WorkoutLogViewSet

router = DefaultRouter()
router.register(r'', WorkoutLogViewSet, basename='workoutlog')

urlpatterns = [
    path('', include(router.urls)),
]