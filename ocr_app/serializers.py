from rest_framework import serializers
from .models import PhotoCard, Passport, DriverLicense

class PhotoCardSerializer(serializers.ModelSerializer):
    class Meta:
        model = PhotoCard
        fields = '__all__'


class PassportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Passport
        fields = '__all__'


class DriverLicenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverLicense
        fields = '__all__'
