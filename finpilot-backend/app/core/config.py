from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = Field("sqlite:///./finpilot.db", alias="DATABASE_URL")
    supabase_url: str | None = Field(None, alias="SUPABASE_URL")
    supabase_anon_key: str | None = Field(None, alias="SUPABASE_ANON_KEY")
    supabase_service_role_key: str | None = Field(None, alias="SUPABASE_SERVICE_ROLE_KEY")

    gemini_api_key: str | None = Field(None, alias="GEMINI_API_KEY")
    gemini_model: str = Field("gemini-2.5-flash", alias="GEMINI_MODEL")

    plaid_client_id: str | None = Field(None, alias="PLAID_CLIENT_ID")
    plaid_secret: str | None = Field(None, alias="PLAID_SECRET")
    plaid_env: str = Field("sandbox", alias="PLAID_ENV")

    twilio_account_sid: str | None = Field(None, alias="TWILIO_ACCOUNT_SID")
    twilio_auth_token: str | None = Field(None, alias="TWILIO_AUTH_TOKEN")
    twilio_phone_number: str | None = Field(None, alias="TWILIO_PHONE_NUMBER")

    demo_profile_id: str = Field("demo", alias="DEMO_PROFILE_ID")

    @property
    def plaid_configured(self) -> bool:
        return bool(self.plaid_client_id and self.plaid_secret)

    @property
    def twilio_configured(self) -> bool:
        return bool(self.twilio_account_sid and self.twilio_auth_token and self.twilio_phone_number)

    @property
    def gemini_configured(self) -> bool:
        return bool(self.gemini_api_key)

    @property
    def supabase_configured(self) -> bool:
        return self.database_url.startswith("postgresql")


@lru_cache
def get_settings() -> Settings:
    return Settings()
