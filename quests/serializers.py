from rest_framework import serializers
from .models import Quest, QuestCompletion


class QuestSerializer(serializers.ModelSerializer):
    assigned_count   = serializers.SerializerMethodField()
    completed_count  = serializers.SerializerMethodField()
    assigned_recruit_ids = serializers.SerializerMethodField()

    class Meta:
        model  = Quest
        fields = [
            'id', 'title', 'description', 'xp_reward', 'coin_reward',
            'difficulty', 'is_community', 'created_at',
            'assigned_count', 'completed_count', 'assigned_recruit_ids',
        ]
        read_only_fields = ['coach', 'created_at']

    def get_assigned_count(self, obj):
        return obj.assigned_to.count()

    def get_completed_count(self, obj):
        return obj.completions.count()

    def get_assigned_recruit_ids(self, obj):
        return list(obj.assigned_to.values_list('id', flat=True))


class QuestCompletionSerializer(serializers.ModelSerializer):
    quest_title  = serializers.CharField(source='quest.title',      read_only=True)
    xp_reward    = serializers.IntegerField(source='quest.xp_reward',   read_only=True)
    coin_reward  = serializers.IntegerField(source='quest.coin_reward',  read_only=True)

    class Meta:
        model  = QuestCompletion
        fields = ['id', 'quest', 'quest_title', 'xp_reward', 'coin_reward', 'completed_at']


# Lightweight serializer for the recruit-facing quest list
class AssignedQuestSerializer(serializers.ModelSerializer):
    is_completed = serializers.SerializerMethodField()

    class Meta:
        model  = Quest
        fields = [
            'id', 'title', 'description', 'xp_reward', 'coin_reward',
            'difficulty', 'is_completed',
        ]

    def get_is_completed(self, obj):
        request = self.context.get('request')
        if request:
            return obj.completions.filter(recruit=request.user).exists()
        return False
