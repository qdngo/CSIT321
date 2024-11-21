from django.db import models

# Create your models here.

class PhotoCard(models.Model):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    address = models.TextField()
    photo_card_number = models.CharField(max_length=50, unique=True)
    date_of_birth = models.DateField()
    card_number = models.CharField(max_length=50)
    gender = models.CharField(max_length=20)
    expiry_date = models.DateField()

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
class Passport(models.Model):
    passport_number = models.CharField(max_length=50, unique=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    nationality = models.CharField(max_length=50)
    date_of_birth = models.DateField()
    gender = models.CharField(max_length=20)
    expiry_date = models.DateField()

    def __str__(self):
        return f"Passport: {self.passport_number} - {self.first_name} {self.last_name}"


class DriverLicense(models.Model):
    license_number = models.CharField(max_length=50, unique=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    date_of_birth = models.DateField()
    address = models.TextField()
    gender = models.CharField(max_length=20)
    expiry_date = models.DateField()

    def __str__(self):
        return f"Driver License: {self.license_number} - {self.first_name} {self.last_name}"