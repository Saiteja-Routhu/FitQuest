from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PoseAnalysisViewSet, RecoveryScoreViewSet, AICoachMessageViewSet

router = DefaultRouter()
router.register(r'pose', PoseAnalysisViewSet, basename='pose')
router.register(r'recovery', RecoveryScoreViewSet, basename='recovery')
router.register(r'messages', AICoachMessageViewSet, basename='ai-coach-messages')

urlpatterns = [
    path('', include(router.urls)),
]
