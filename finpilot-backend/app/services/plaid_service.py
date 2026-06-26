from plaid import ApiClient, Configuration, Environment
from plaid.api import plaid_api
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.sandbox_public_token_create_request import SandboxPublicTokenCreateRequest
from plaid.model.transactions_sync_request import TransactionsSyncRequest

from app.core.config import Settings


class PlaidService:
    def __init__(self, settings: Settings):
        self.settings = settings
        if settings.plaid_env != "sandbox":
            raise ValueError("Only Plaid Sandbox is supported for this hackathon backend.")

        config = Configuration(
            host=Environment.Sandbox,
            api_key={
                "clientId": settings.plaid_client_id or "",
                "secret": settings.plaid_secret or "",
            },
        )
        self.client = plaid_api.PlaidApi(ApiClient(config))

    def require_configured(self) -> None:
        if not self.settings.plaid_configured:
            raise RuntimeError("Plaid credentials are not configured.")

    def create_link_token(self, profile_id: str) -> dict:
        self.require_configured()
        request = LinkTokenCreateRequest(
            products=[Products("transactions")],
            client_name="FinPilot",
            country_codes=[CountryCode("US")],
            language="en",
            user=LinkTokenCreateRequestUser(client_user_id=profile_id),
        )
        return self.client.link_token_create(request).to_dict()

    def create_sandbox_public_token(self, institution_id: str, products: list[str]) -> dict:
        self.require_configured()
        request = SandboxPublicTokenCreateRequest(
            institution_id=institution_id,
            initial_products=[Products(product) for product in products],
        )
        return self.client.sandbox_public_token_create(request).to_dict()

    def exchange_public_token(self, public_token: str) -> dict:
        self.require_configured()
        request = ItemPublicTokenExchangeRequest(public_token=public_token)
        return self.client.item_public_token_exchange(request).to_dict()

    def sync_transactions(self, access_token: str) -> dict:
        self.require_configured()
        cursor = None
        combined: dict = {"accounts": [], "added": [], "modified": [], "removed": []}

        while True:
            kwargs = {"access_token": access_token}
            if cursor is not None:
                kwargs["cursor"] = cursor
            request = TransactionsSyncRequest(**kwargs)
            payload = self.client.transactions_sync(request).to_dict()

            if payload.get("accounts"):
                combined["accounts"] = payload["accounts"]
            combined["added"].extend(payload.get("added", []))
            combined["modified"].extend(payload.get("modified", []))
            combined["removed"].extend(payload.get("removed", []))

            cursor = payload.get("next_cursor")
            combined["next_cursor"] = cursor
            combined["request_id"] = payload.get("request_id")
            if not payload.get("has_more"):
                combined["has_more"] = False
                return combined
