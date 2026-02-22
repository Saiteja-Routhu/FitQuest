import os
from django.core.management.base import BaseCommand
from users.models import CustomUser


class Command(BaseCommand):
    help = 'Create the HIGH_COUNCIL admin user from environment variables'

    def handle(self, *args, **kwargs):
        username = os.environ.get('ADMIN_USERNAME', 'admin')
        email    = os.environ.get('ADMIN_EMAIL',    'admin@fitquest.com')
        password = os.environ.get('ADMIN_PASSWORD', '')

        if not password:
            self.stdout.write(self.style.WARNING('ADMIN_PASSWORD not set — skipping admin creation'))
            return

        if CustomUser.objects.filter(username=username).exists():
            self.stdout.write(self.style.WARNING(f'Admin "{username}" already exists — skipping'))
            return

        CustomUser.objects.create_superuser(username=username, email=email, password=password)
        self.stdout.write(self.style.SUCCESS(f'Admin "{username}" created with role HIGH_COUNCIL'))
