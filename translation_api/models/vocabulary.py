# SQLAlchemy models no longer used - PocketBase handles schema
# from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
# from sqlalchemy.sql import func
# from sqlalchemy.orm import relationship
# from core.database import Base


class Vocabulary(Base):
    __tablename__ = "vocabulary"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    word = Column(String, nullable=False, index=True)
    translation = Column(String, nullable=True)
    source_lang = Column(String(10), nullable=False)
    target_lang = Column(String(10), nullable=False)
    count = Column(Integer, default=1)  # How many times encountered
    is_mastered = Column(Boolean, default=False)
    first_seen = Column(DateTime(timezone=True), server_default=func.now())
    last_reviewed = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="vocabulary")

