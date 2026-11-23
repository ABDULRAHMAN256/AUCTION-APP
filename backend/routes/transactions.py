# routes/transactions.py — receipts + payment + delivery + confirmation
from fastapi import APIRouter, HTTPException, Depends
from sqlmodel import Session, select
from database import get_session
from models import Transaction
from auth import get_current_user
from pydantic import BaseModel
from datetime import datetime, timezone

router = APIRouter()


class PaymentRequest(BaseModel):
    payment_reference: str


@router.get("/me")
def my_transactions(user: dict = Depends(get_current_user), session: Session = Depends(get_session)):
    txns = session.exec(
        select(Transaction).where(Transaction.buyer_id == user["id"]).order_by(Transaction.created_at.desc())
    ).all()
    return [t.model_dump() for t in txns]


@router.post("/{transaction_id}/pay")
def pay_transaction(
    transaction_id: int,
    body: PaymentRequest,
    user: dict = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    txn = session.get(Transaction, transaction_id)
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    if txn.buyer_id != user["id"]:
        raise HTTPException(status_code=403, detail="Only the buyer can pay")

    if txn.payment_status == "paid":
        raise HTTPException(status_code=400, detail="Already paid")

    txn.payment_status = "paid"
    txn.paid_at = datetime.now(timezone.utc)
    session.add(txn)
    session.commit()

    return {
        "transaction_id": txn.transaction_id,
        "asset_id": txn.asset_id,
        "final_amount": txn.final_amount,
        "payment_status": txn.payment_status,
        "paid_at": txn.paid_at.isoformat() if txn.paid_at else None,
        "payment_reference": body.payment_reference,
    }


@router.post("/{transaction_id}/deliver")
def deliver_transaction(
    transaction_id: int,
    user: dict = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    txn = session.get(Transaction, transaction_id)
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    if txn.payment_status != "paid":
        raise HTTPException(status_code=400, detail="Cannot deliver before payment")

    txn.delivery_status = "delivered"
    txn.delivered_at = datetime.now(timezone.utc)
    session.add(txn)
    session.commit()

    return {
        "transaction_id": txn.transaction_id,
        "delivery_status": txn.delivery_status,
        "delivered_at": txn.delivered_at.isoformat() if txn.delivered_at else None,
    }


@router.post("/{transaction_id}/confirm")
def confirm_receipt(
    transaction_id: int,
    user: dict = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    txn = session.get(Transaction, transaction_id)
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")

    if txn.buyer_id != user["id"]:
        raise HTTPException(status_code=403, detail="Only the buyer can confirm receipt")

    if txn.delivery_status != "delivered":
        raise HTTPException(status_code=400, detail="Cannot confirm before delivery")

    txn.confirmed_at = datetime.now(timezone.utc)
    txn.delivery_status = "completed"
    session.add(txn)
    session.commit()

    return {
        "transaction_id": txn.transaction_id,
        "delivery_status": txn.delivery_status,
        "confirmed_at": txn.confirmed_at.isoformat() if txn.confirmed_at else None,
    }