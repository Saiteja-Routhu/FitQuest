from django.db import models
from users.models import CustomUser


class ChatGroup(models.Model):
    name = models.CharField(max_length=100)
    created_by = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='created_groups')
    members = models.ManyToManyField(
        CustomUser, related_name='chat_groups', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.name} (by {self.created_by.username})'


class Message(models.Model):
    sender    = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='sent_messages')
    recipient = models.ForeignKey(
        CustomUser, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='received_messages')
    group = models.ForeignKey(
        ChatGroup, on_delete=models.CASCADE, null=True, blank=True,
        related_name='messages')
    # recipient=None and group=None means community broadcast
    # group set means group chat message
    # recipient set means DM
    content   = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read   = models.BooleanField(default=False)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        if self.group:
            return f'{self.sender.username} → [{self.group.name}]: {self.content[:40]}'
        target = self.recipient.username if self.recipient else 'BROADCAST'
        return f'{self.sender.username} → {target}: {self.content[:40]}'
