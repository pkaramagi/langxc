# SQLAlchemy models no longer used - PocketBase handles schema
# from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
# from sqlalchemy.sql import func
# from sqlalchemy.orm import relationship
# from core.database import Base


class Translation(Base):
    __tablename__ = "translations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    source_text = Column(Text, nullable=False)
    translated_text = Column(Text, nullable=False)
    source_lang = Column(String(10), nullable=False)  # 'ko' or 'en'
    target_lang = Column(String(10), nullable=False)  # 'ko' or 'en'
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="translations")

