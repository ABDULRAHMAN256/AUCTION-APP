# models.py — SQLModel table classes (one per ERD table) + request schemas
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional


# ---------- ERD TABLES (one class per table) ----------

class User(SQLModel, table=True):
    __tablename__ = "users"
    user_id: int = Field(default=None, primary_key=True)
    username: str = Field(max_length=50, unique=True, index=True)
    email: str = Field(max_length=255, unique=True, index=True)
    password_hash: str = Field(max_length=255)
    full_name: str = Field(default=None, max_length=100)
    phone: str = Field(default=None, max_length=20)
    role: str = Field(default="both", max_length=10)
    kyc_status: str = Field(default="pending", max_length=10)
    email_verified: bool = Field(default=False)
    verification_code: str = Field(default=None, max_length=10)
    verification_code_expires_at: datetime = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Category(SQLModel, table=True):
    __tablename__ = "categories"
    category_id: int = Field(default=None, primary_key=True)
    name: str = Field(max_length=50, unique=True)


class Asset(SQLModel, table=True):
    __tablename__ = "assets"
    asset_id: int = Field(default=None, primary_key=True)
    seller_id: int = Field(foreign_key="users.user_id")
    category_id: int = Field(foreign_key="categories.category_id")
    title: str = Field(max_length=150)
    description: str = None
    starting_price: float
    reserve_price: float
    min_increment: float = 500000.00
    current_price: float
    status: str = Field(default="scheduled", max_length=10)
    start_time: datetime
    end_time: datetime
    created_at: datetime = Field(default_factory=datetime.utcnow)


class AssetImage(SQLModel, table=True):
    __tablename__ = "asset_images"
    image_id: int = Field(default=None, primary_key=True)
    asset_id: int = Field(foreign_key="assets.asset_id")
    file_path: str = Field(max_length=255)
    is_primary: bool = Field(default=False)


class Bid(SQLModel, table=True):
    __tablename__ = "bids"
    bid_id: int = Field(default=None, primary_key=True)
    asset_id: int = Field(foreign_key="assets.asset_id")
    user_id: int = Field(foreign_key="users.user_id")
    bid_amount: float
    placed_at: datetime = Field(default_factory=datetime.utcnow)


class KYCDocument(SQLModel, table=True):
    __tablename__ = "kyc_documents"
    kyc_id: int = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.user_id")
    document_type: str = Field(max_length=30)
    document_number: str = Field(max_length=50)
    file_path: str = Field(max_length=255)
    status: str = Field(default="pending", max_length=10)
    reviewed_by: int = Field(default=None, foreign_key="users.user_id")
    reviewed_at: datetime = None
    submitted_at: datetime = Field(default_factory=datetime.utcnow)


class Deposit(SQLModel, table=True):
    __tablename__ = "deposits"
    deposit_id: int = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.user_id")
    asset_id: int = Field(foreign_key="assets.asset_id")
    amount: float
    status: str = Field(max_length=10)
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Transaction(SQLModel, table=True):
    __tablename__ = "transactions"
    transaction_id: int = Field(default=None, primary_key=True)
    asset_id: int = Field(foreign_key="assets.asset_id", unique=True)
    buyer_id: int = Field(foreign_key="users.user_id")
    final_amount: float
    payment_status: str = Field(default="pending", max_length=15)
    delivery_status: str = Field(default="pending", max_length=20)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    paid_at: datetime = None
    delivered_at: datetime = None
    confirmed_at: datetime = None


# ---------- REQUEST SCHEMAS (no table=True) ----------

class RegisterRequest(SQLModel):
    username: str = Field(min_length=3, max_length=50)
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=8)
    full_name: str = None
    phone: str = None
    role: str = "both"


class LoginRequest(SQLModel):
    username: str
    password: str


class BidCreate(SQLModel):
    asset_id: int
    bid_amount: float


class AssetCreate(SQLModel):
    category_id: int
    title: str
    description: str = None
    starting_price: float
    reserve_price: float
    min_increment: float
    start_time: str
    end_time: str
    images: list[str] = None


class AssetUpdate(SQLModel):
    title: str = None
    description: str = None
    reserve_price: float = None
    min_increment: float = None
    end_time: str = None