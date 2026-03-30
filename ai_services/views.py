from rest_framework import viewsets, permissions, mixins
from .models import PoseAnalysis, RecoveryScore, AICoachMessage
from .serializers import PoseAnalysisSerializer, RecoveryScoreSerializer, AICoachMessageSerializer


class PoseAnalysisViewSet(viewsets.ModelViewSet):
    serializer_class = PoseAnalysisSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return PoseAnalysis.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class RecoveryScoreViewSet(viewsets.ModelViewSet):
    serializer_class = RecoveryScoreSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return RecoveryScore.objects.filter(user=self.request.user)


class AICoachMessageViewSet(mixins.ListModelMixin,
                             mixins.UpdateModelMixin,
                             viewsets.GenericViewSet):
    serializer_class = AICoachMessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return AICoachMessage.objects.filter(user=self.request.user)
