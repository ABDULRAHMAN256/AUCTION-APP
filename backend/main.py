# main.py — FastAPI entry point
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from database import init_db
from routes import auth, assets, bids, kyc, deposits, transactions


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    print("[db] initialized")
    yield


app = FastAPI(
    title="Uganda Public Asset Auction API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health", tags=["System"])
def health():
    return {"ok": True}

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(assets.router, prefix="/api/v1/assets", tags=["Assets"])
app.include_router(bids.router, prefix="/api/v1", tags=["Bids"])
app.include_router(kyc.router, prefix="/api/v1/kyc", tags=["KYC"])
app.include_router(deposits.router, prefix="/api/v1/deposits", tags=["Deposits"])
app.include_router(transactions.router, prefix="/api/v1/transactions", tags=["Transactions"])