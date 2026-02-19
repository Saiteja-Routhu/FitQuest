from rest_framework import viewsets, permissions
from .models import PoseAnalysis, RecoveryScore
from .serializers import PoseAnalysisSerializer, RecoveryScoreSerializer


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