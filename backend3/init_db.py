from database import Base, engine
from models import User, Event  # VERY IMPORTANT: import models here

print("🔄 Creating tables...")
Base.metadata.create_all(bind=engine)
print("✅ Done!")
