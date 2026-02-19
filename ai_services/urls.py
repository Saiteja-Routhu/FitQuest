from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PoseAnalysisViewSet, RecoveryScoreViewSet

router = DefaultRouter()
router.register(r'pose', PoseAnalysisViewSet, basename='pose')
router.register(r'recovery', RecoveryScoreViewSet, basename='recovery')

urlpatterns = [
    path('', include(router.urls)),
]