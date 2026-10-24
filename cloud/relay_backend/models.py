from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class RequestSubmission(StrictModel):
    schema_version: Literal[1] = 1
    operation_id: UUID
    request_id: UUID
    incident_id: str = Field(min_length=1, max_length=80, pattern=r"^[a-zA-Z0-9_-]+$")
    destination_shelter_id: str = Field(min_length=1, max_length=80, pattern=r"^[a-zA-Z0-9_-]+$")
    origin_device_id: UUID
    original_text: str = Field(min_length=1, max_length=4096)
    input_mode: Literal["text", "reviewed_transcript"]
    transcription_id: UUID | None = None
    created_at: datetime
    expires_at: datetime
    revision: Literal[1] = 1

    @field_validator("created_at", "expires_at")
    @classmethod
    def aware(cls, value):
        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("An explicit UTC offset is required")
        return value

    @field_validator("original_text")
    @classmethod
    def nonblank(cls, value):
        if not value.strip() or any(ord(c) < 32 and c not in "\n\r\t" for c in value):
            raise ValueError("Text must be nonblank and contain no control characters")
        return value

    @model_validator(mode="after")
    def mode_matches(self):
        if (self.input_mode == "reviewed_transcript") != (self.transcription_id is not None):
            raise ValueError("Only reviewed_transcript input must include transcription_id")
        return self


class TranscriptionAllocation(StrictModel):
    schema_version: Literal[1] = 1
    operation_id: UUID
    transcription_id: UUID
    incident_id: str = Field(min_length=1, max_length=80, pattern=r"^[a-zA-Z0-9_-]+$")
    content_type: Literal["audio/wav"] = "audio/wav"
    byte_length: int = Field(strict=True, ge=45, le=2_097_152)
    sha256: str = Field(pattern=r"^[a-f0-9]{64}$")
    language_code: Literal["en-US"] = "en-US"


class StartTranscription(StrictModel):
    operation_id: UUID


class ModelProposal(StrictModel):
    item_id: Literal["water_packs", "blankets", "food_packs", "other"] | None
    quantity: int | None = Field(default=None, strict=True, ge=1, le=10000)
    unit: Literal["pack", "piece", "bottle"] | None
    shelter_id: str | None = Field(max_length=80)
    negated: bool = Field(strict=True)
    missing_fields: list[Literal["item", "quantity", "unit", "shelter"]] = Field(max_length=4)
    summary: str = Field(min_length=1, max_length=400)


class ErrorDetail(StrictModel):
    code: str
    message: str
    retryable: bool = False


class ErrorResponse(StrictModel):
    error: ErrorDetail


class ValidatedResult(StrictModel):
    status: Literal["ready_for_review", "needs_review"]
    proposal: ModelProposal | None
    review_reasons: list[str]
    allocation_authorized: Literal[False] = False


class RequestResult(StrictModel):
    request_id: UUID
    schema_version: Literal[1]
    revision: Literal[1]
    submission: RequestSubmission
    accepted_at: datetime
    cloud_state: Literal["accepted"]
    analysis_state: Literal["pending", "retrying", "ready_for_review", "needs_review", "failed"]
    result: ValidatedResult | None
    analysis_attempts: int
    manual_retry_count: int = 0
    error: ErrorDetail | None
    provider_evidence: dict | None
    assignment_state: Literal["not_implemented"]
    fulfillment_state: Literal["not_implemented"]


class RequestPage(StrictModel):
    items: list[RequestResult]
    next_cursor: str | None


class UploadAuthorization(StrictModel):
    method: Literal["POST", "PUT"]
    url: str
    fields: dict[str, str]
    headers: dict[str, str]
    requires_bearer_token: bool
    expires_in_seconds: int


class TranscriptionResult(StrictModel):
    schema_version: Literal[1]
    transcription_id: UUID
    incident_id: str
    content_type: Literal["audio/wav"]
    byte_length: int
    sha256: str
    language_code: Literal["en-US"]
    status: Literal["awaiting_upload", "upload_expired", "queued", "processing", "completed", "failed"]
    created_at: float
    upload_expires_at: float
    transcript: str | None
    error: ErrorDetail | None
    provider_evidence: dict | None
    start_count: int
    started_at: float | None = None
    duration_seconds: float | None = None
    sample_rate: int | None = None
    upload: UploadAuthorization | None = None


class DirectoryEntry(StrictModel):
    shelter_id: str
    incident_id: str
    display_name: str


class ShelterDirectory(StrictModel):
    schema_version: Literal[1]
    items: list[DirectoryEntry]


class Health(StrictModel):
    status: Literal["ok"]
    api_version: str
    schema_version: Literal[1]
    mode: Literal["local-test", "aws"]
    storage: Literal["sqlite", "dynamodb"]
    performs_ai_check: Literal[False] = False
    note: str
