from sqlalchemy.orm import Session
from datetime import datetime
from models import Event

def log_event(db: Session, user_id: int, tmdb_id: int, event_type: str):
    event = Event(
        user_id=user_id,
        tmdb_id=tmdb_id,
        event_type=event_type,
        timestamp=datetime.utcnow(),
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event
