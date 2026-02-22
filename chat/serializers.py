from rest_framework import serializers
from .models import Message, ChatGroup


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.username', read_only=True)

    class Meta:
        model = Message
        fields = ['id', 'sender', 'sender_name', 'recipient', 'group',
                  'content', 'created_at', 'is_read']
        read_only_fields = ['sender', 'created_at']


class ChatGroupSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    member_ids = serializers.PrimaryKeyRelatedField(
        source='members', many=True, read_only=True)

    class Meta:
        model = ChatGroup
        fields = ['id', 'name', 'created_by', 'created_by_name',
                  'member_ids', 'created_at']
        read_only_fields = ['created_by', 'created_at']
