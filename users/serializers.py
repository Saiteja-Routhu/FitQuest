from rest_framework import serializers
from .models import CustomUser, CoachAccessKey, AssessmentForm


# 1. Assessment Serializer
class AssessmentFormSerializer(serializers.ModelSerializer):
    class Meta:
        model = AssessmentForm
        fields = '__all__'


# 2. User Serializer (Expanded)
class UserSerializer(serializers.ModelSerializer):
    assessment = AssessmentFormSerializer(read_only=True)  # Nested data

    class Meta:
        model = CustomUser
        fields = [
            'id', 'username', 'email', 'role', 'xp', 'level', 'coins',
            'coach', 'is_new_assignment', 'goal', 'activity_level', 'assessment'
        ]


# 3. Register Serializer (Unchanged)
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    access_key = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'password', 'role', 'access_key', 'height', 'weight', 'activity_level', 'goal']

    def create(self, validated_data):
        access_key = validated_data.pop('access_key', None)
        height = validated_data.pop('height', None)
        weight = validated_data.pop('weight', None)
        role = validated_data.get('role', 'RECRUIT')

        if role in ('GUILD_MASTER', 'SUPER_COACH'):
            required_key_type = 'COACH' if role == 'GUILD_MASTER' else 'SUPER_COACH'
            if not access_key:
                raise serializers.ValidationError({"access_key": "Access key is required."})
            try:
                key_obj = CoachAccessKey.objects.get(
                    key=access_key, is_used=False, key_type=required_key_type)
                key_obj.is_used = True
                key_obj.used_by = validated_data['username']
                key_obj.save()
            except CoachAccessKey.DoesNotExist:
                raise serializers.ValidationError({"access_key": "Invalid or used access key for this role."})

        user = CustomUser.objects.create_user(**validated_data)

        if role == 'RECRUIT':
            user.height = height
            user.weight = weight
            user.save()

        return user


# 4. Login Serializer
class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)