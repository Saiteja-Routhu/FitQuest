from django.db.models import Q
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Message, ChatGroup
from .serializers import MessageSerializer, ChatGroupSerializer
from users.models import CustomUser


class DMConversationView(APIView):
    """GET /api/chat/dm/<athlete_id>/ — returns the full DM thread between coach and athlete."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, athlete_id):
        messages = Message.objects.filter(
            (Q(sender=request.user) & Q(recipient_id=athlete_id)) |
            (Q(sender_id=athlete_id) & Q(recipient=request.user))
        ).order_by('created_at')
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)


class CommunityFeedView(generics.ListAPIView):
    """GET /api/chat/community/ — community broadcast feed for the coach's team."""
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        # Determine coach and roster
        if user.role == 'GUILD_MASTER':
            coach = user
            roster_ids = list(user.recruits.values_list('id', flat=True))
        elif user.role == 'RECRUIT' and user.coach:
            coach = user.coach
            roster_ids = list(coach.recruits.values_list('id', flat=True))
        else:
            return Message.objects.none()

        team_ids = roster_ids + [coach.id]
        return Message.objects.filter(
            sender_id__in=team_ids,
            recipient__isnull=True,
        ).order_by('created_at')


class SendMessageView(APIView):
    """POST /api/chat/send/ — send a DM, broadcast, or group message."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        content = request.data.get('content', '').strip()
        if not content:
            return Response({'error': 'Content is required'}, status=status.HTTP_400_BAD_REQUEST)

        group_id = request.data.get('group_id')
        recipient_id = request.data.get('recipient_id')

        group = None
        recipient = None

        if group_id is not None:
            try:
                group = ChatGroup.objects.get(id=group_id)
                if request.user not in group.members.all() and group.created_by != request.user:
                    return Response({'error': 'Not a group member'}, status=403)
            except ChatGroup.DoesNotExist:
                return Response({'error': 'Group not found'}, status=status.HTTP_404_NOT_FOUND)
        elif recipient_id is not None:
            try:
                recipient = CustomUser.objects.get(id=recipient_id)
            except CustomUser.DoesNotExist:
                return Response({'error': 'Recipient not found'}, status=status.HTTP_404_NOT_FOUND)

        msg = Message.objects.create(
            sender=request.user,
            recipient=recipient,
            group=group,
            content=content,
        )
        return Response(MessageSerializer(msg).data, status=status.HTTP_201_CREATED)


class MarkReadView(APIView):
    """POST /api/chat/read/<pk>/ — mark a message as read."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            msg = Message.objects.get(id=pk, recipient=request.user)
            msg.is_read = True
            msg.save()
            return Response({'message': 'Marked as read'})
        except Message.DoesNotExist:
            return Response({'error': 'Message not found'}, status=status.HTTP_404_NOT_FOUND)


class GroupListView(APIView):
    """GET /api/chat/groups/ — groups where user is creator or member."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        groups = ChatGroup.objects.filter(
            Q(created_by=request.user) | Q(members=request.user)
        ).distinct()
        return Response(ChatGroupSerializer(groups, many=True).data)


class CreateGroupView(APIView):
    """POST /api/chat/groups/create/ — create a group chat."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        name = request.data.get('name', '').strip()
        if not name:
            return Response({'error': 'Name is required'}, status=400)
        member_ids = request.data.get('member_ids', [])

        group = ChatGroup.objects.create(name=name, created_by=request.user)
        members = CustomUser.objects.filter(id__in=member_ids)
        group.members.set(members)
        # Creator is also implicitly in the group
        return Response(ChatGroupSerializer(group).data, status=201)


class GroupConversationView(APIView):
    """GET /api/chat/group/<group_id>/ — messages for a group."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, group_id):
        try:
            group = ChatGroup.objects.get(id=group_id)
        except ChatGroup.DoesNotExist:
            return Response({'error': 'Group not found'}, status=404)

        if request.user != group.created_by and request.user not in group.members.all():
            return Response({'error': 'Not a member'}, status=403)

        messages = Message.objects.filter(group=group).order_by('created_at')
        return Response(MessageSerializer(messages, many=True).data)
