# routes/auth.py
import random
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, HTTPException, Depends
from sqlmodel import Session, select
from database import get_session
from models import User, RegisterRequest, LoginRequest
from auth import hash_password, verify_password, create_access_token

router = APIRouter()

ALLOWED_ROLES = ("bidder", "seller", "both")


@router.post("/register", status_code=201)
def register(body: RegisterRequest, session: Session = Depends(get_session)):
    # Role whitelist — admin cannot self-register
    if body.role and body.role not in ALLOWED_ROLES:
        raise HTTPException(
            status_code=400,
            detail=f"Role must be one of: {', '.join(ALLOWED_ROLES)}"
        )

    existing = session.exec(
        select(User).where((User.username == body.username) | (User.email == body.email))
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username or email already exists")

    new_user = User(
        username=body.username,
        email=body.email,
        password_hash=hash_password(body.password),
        full_name=body.full_name,
        phone=body.phone,
        role=body.role or "both",
        kyc_status="pending",
        email_verified=False,
        created_at=datetime.now(timezone.utc),
    )
    session.add(new_user)
    session.commit()
    session.refresh(new_user)

    token = create_access_token(new_user.user_id, new_user.role)
    return {
        "token": token,
        "user_id": new_user.user_id,
        "role": new_user.role,
    }


@router.post("/login")
def login(body: LoginRequest, session: Session = Depends(get_session)):
    user = session.exec(
        select(User).where((User.username == body.username) | (User.email == body.username))
    ).first()

    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(user.user_id, user.role)
    return {
        "token": token,
        "user": {
            "user_id": user.user_id,
            "username": user.username,
            "role": user.role,
            "kyc_status": user.kyc_status,
            "email_verified": user.email_verified,
        }
    }


@router.post("/send-verification-email")
def send_verification_email(body: dict, session: Session = Depends(get_session)):
    email = body.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Email required")

    user = session.exec(select(User).where(User.email == email)).first()
    if not user:
        raise HTTPException(status_code=404, detail="No account with that email")

    if user.email_verified:
        return {"message": "Email already verified"}

    code = f"{random.randint(100000, 999999)}"
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)

    user.verification_code = code
    user.verification_code_expires_at = expires_at
    session.add(user)
    session.commit()

    # In production: send via SendGrid
    return {
        "message": "Verification code sent to your email",
        "demo_code": code,
    }


@router.post("/verify-email")
def verify_email(body: dict, session: Session = Depends(get_session)):
    email = body.get("email")
    code = body.get("code")
    if not email or not code:
        raise HTTPException(status_code=400, detail="Email and code required")

    user = session.exec(select(User).where(User.email == email)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.email_verified:
        return {"message": "Email already verified"}

    if user.verification_code != code:
        raise HTTPException(status_code=400, detail="Invalid code")

    if user.verification_code_expires_at and user.verification_code_expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Verification code expired")

    user.email_verified = True
    user.verification_code = None
    user.verification_code_expires_at = None
    session.add(user)
    session.commit()

    return {"message": "Email verified successfully"}