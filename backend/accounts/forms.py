"""Admin forms for the custom User model.

A custom user model needs its own create/change forms because the default
``UserCreationForm``/``UserChangeForm`` reference the username field.
"""

from django.contrib.auth.forms import UserChangeForm, UserCreationForm

from .models import User


class UserAdminCreationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ("email", "role")


class UserAdminChangeForm(UserChangeForm):
    class Meta:
        model = User
        fields = "__all__"
