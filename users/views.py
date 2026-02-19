from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from .models import CustomUser, CoachAccessKey
from .serializers import UserSerializer, RegisterSerializer, LoginSerializer

class RegisterView(generics.CreateAPIView):
    queryset = CustomUser.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            username = serializer.validated_data['username']
            password = serializer.validated_data['password']
            user = authenticate(username=username, password=password)

            if user:
                token, _ = Token.objects.get_or_create(user=user)
                return Response({
                    "token": token.key,
                    "role": user.role,
                    "user": UserSerializer(user).data,
                    "message": "Login Successful"
                })
            return Response({"error": "Invalid Credentials"}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class GenerateCoachKeyView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        new_key = CoachAccessKey.generate_key()
        CoachAccessKey.objects.create(key=new_key)
        return Response({"key": new_key}, status=status.HTTP_201_CREATED)

class UserListView(generics.ListAPIView):
    queryset = CustomUser.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]


# ... (Keep existing imports and views: Register, Login, GenerateKey, UserList)

# 5. Coach Roster View (Get My Recruits)
class CoachRosterView(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Only return users where coach = Current Logged In User
        return CustomUser.objects.filter(coach=self.request.user)


# 6. Admin Assignment View (High Council Only)
class AssignCoachView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        recruit_id = request.data.get('recruit_id')
        coach_id = request.data.get('coach_id')

        try:
            recruit = CustomUser.objects.get(id=recruit_id, role='RECRUIT')
            coach = CustomUser.objects.get(id=coach_id, role='GUILD_MASTER')

            recruit.coach = coach
            recruit.is_new_assignment = True  # Trigger notification
            recruit.save()

            return Response({"message": f"Assigned {recruit.username} to {coach.username}"})
        except CustomUser.DoesNotExist:
            return Response({"error": "User not found"}, status=404)

# ... existing imports

class AcknowledgeRecruitView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        recruit_id = request.data.get('recruit_id')
        try:
            # Ensure this recruit actually belongs to the logged-in Coach
            recruit = CustomUser.objects.get(id=recruit_id, coach=request.user)
            recruit.is_new_assignment = False
            recruit.save()
            return Response({"message": "Recruit acknowledged"})
        except CustomUser.DoesNotExist:
            return Response({"error": "Recruit not found or not yours"}, status=404)