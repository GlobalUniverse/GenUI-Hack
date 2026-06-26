from pydantic import BaseModel


class SandboxPublicTokenRequest(BaseModel):
    profile_id: str = "demo"
    institution_id: str = "ins_109508"
    products: list[str] = ["transactions"]


class SandboxPublicTokenResponse(BaseModel):
    public_token: str
    request_id: str | None = None


class ExchangeTokenRequest(BaseModel):
    profile_id: str = "demo"
    public_token: str


class ExchangeTokenResponse(BaseModel):
    item_id: str | None = None
    stored: bool
    snapshot_synced: bool = False


class LinkTokenRequest(BaseModel):
    profile_id: str = "demo"


class LinkTokenResponse(BaseModel):
    link_token: str
    expiration: str | None = None
    request_id: str | None = None
