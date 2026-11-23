# routes/deposits.py
from fastapi import APIRouter, HTTPException, Depends
from sqlmodel import Session, select
from database import get_session
from models import Deposit, Asset, User
from auth import get_current_user
from pydantic import BaseModel
from datetime import datetime, timezone

router = APIRouter()


class DepositCreate(BaseModel):
    asset_id: int
    amount: float
    payment_ref: str


@router.post("/", status_code=201)
def create_deposit(
    body: DepositCreate,
    user: dict = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if user["role"] == "admin":
        raise HTTPException(status_code=403, detail="Administrators cannot place deposits")

    if body.amount <= 0:
        raise HTTPException(status_code=400, detail="amount must be positive")

    asset = session.get(Asset, body.asset_id)
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    # Anti-self-deposit
    if asset.seller_id == user["id"]:
        raise HTTPException(status_code=403, detail="You cannot deposit on your own asset")

    # KYC gate
    user_obj = session.get(User, user["id"])
    if not user_obj or user_obj.kyc_status != "approved":
        raise HTTPException(status_code=403, detail="KYC must be approved before depositing")

    dep = Deposit(
        user_id=user["id"],
        asset_id=body.asset_id,
        amount=body.amount,
        status="paid",
        created_at=datetime.now(timezone.utc),
    )
    session.add(dep)
    session.commit()
    session.refresh(dep)
    return {"deposit_id": dep.deposit_id, "payment_ref": body.payment_ref}


@router.get("/me")
def my_deposits(user: dict = Depends(get_current_user), session: Session = Depends(get_session)):
    deposits = session.exec(
        select(Deposit).where(Deposit.user_id == user["id"]).order_by(Deposit.created_at.desc())
    ).all()
    return [d.model_dump() for d in deposits]