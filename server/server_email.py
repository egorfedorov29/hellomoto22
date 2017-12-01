from flask import render_template
from flask import Flask
from flask_mail import Mail, Message

from models import User


def send_welcome_email(flask_mail, user, password, login_url):
    msg = Message(
        subject="Registration at BestMiner",
        recipients=[user.email],
        body=render_template("email/welcome_email.txt", user=user, password=password, login_url=login_url)
    )
    flask_mail.send(msg)

def send_subscribe_email(flask_mail, email):
    msg = Message(
        subject="Registration at BestMiner (beta)",
        recipients = [email],
        cc =['bestminer@egorbs.ru'],
        bcc=['egor.fedorov@gmail.com'],
        body=render_template("email/subscribe_to_beta_email.txt", email=email)
    )
    flask_mail.send(msg)


def send_feedback_message(flask_mail, email, name, message):
    msg = Message(
        subject = "Feedback message from {}".format(name),
        recipients = ['bestminer@egorbs.ru'],
        cc =[email],
        bcc = ['egor.fedorov@gmail.com'],
        body = message
    )
    flask_mail.send(msg)

