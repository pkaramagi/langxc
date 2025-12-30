"""
Simple test script to verify the API is working.
Run this after starting the server: python test_api.py
"""
import requests
import json

BASE_URL = "http://localhost:8000"


def test_health():
    """Test health endpoint."""
    print("🔍 Testing health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.json()}")
    assert response.status_code == 200
    print("✅ Health check passed!\n")


def test_register_and_login():
    """Test user registration and login."""
    print("🔍 Testing user registration...")
    
    # Register
    register_data = {
        "email": "testuser@example.com",
        "password": "testpass123",
        "display_name": "Test User"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
        if response.status_code == 201:
            print("✅ Registration successful!")
            token = response.json()["access_token"]
            print(f"   Token: {token[:20]}...")
            return token
        elif response.status_code == 400:
            print("⚠️  User already exists, trying login...")
            
            # Try login instead
            login_data = {
                "email": register_data["email"],
                "password": register_data["password"]
            }
            response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
            if response.status_code == 200:
                token = response.json()["access_token"]
                print("✅ Login successful!")
                print(f"   Token: {token[:20]}...")
                return token
    except Exception as e:
        print(f"❌ Error: {e}")
        return None


def test_translations(token):
    """Test translation endpoints."""
    print("\n🔍 Testing translation creation...")
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    translation_data = {
        "source_text": "안녕하세요, 반갑습니다!",
        "translated_text": "Hello, nice to meet you!",
        "source_lang": "ko",
        "target_lang": "en"
    }
    
    response = requests.post(
        f"{BASE_URL}/translations",
        json=translation_data,
        headers=headers
    )
    
    if response.status_code == 201:
        print("✅ Translation created!")
        print(f"   Translation ID: {response.json()['id']}")
    else:
        print(f"❌ Failed: {response.status_code}")
        print(f"   {response.text}")
        return
    
    # Get translations
    print("\n🔍 Fetching translations...")
    response = requests.get(f"{BASE_URL}/translations", headers=headers)
    if response.status_code == 200:
        translations = response.json()
        print(f"✅ Found {len(translations)} translation(s)")
        if translations:
            print(f"   Latest: {translations[0]['source_text'][:30]}...")
    
    # Get stats
    print("\n🔍 Fetching statistics...")
    response = requests.get(f"{BASE_URL}/translations/stats", headers=headers)
    if response.status_code == 200:
        stats = response.json()
        print("✅ Statistics:")
        print(f"   Total: {stats['total_translations']}")
        print(f"   This week: {stats['this_week']}")
        print(f"   Today: {stats['today']}")


def test_weekly_summary(token):
    """Test weekly summary endpoint."""
    print("\n🔍 Testing weekly summary...")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/translations/weekly-summary",
        headers=headers
    )
    
    if response.status_code == 200:
        summary = response.json()
        print("✅ Weekly summary:")
        print(f"   Total translations: {summary['total_translations']}")
        print(f"   Unique words: {summary['unique_words']}")
        if summary['most_frequent_words']:
            print(f"   Most frequent word: {summary['most_frequent_words'][0]['word']}")
    else:
        print(f"❌ Failed: {response.status_code}")


def test_vocabulary(token):
    """Test vocabulary endpoints."""
    print("\n🔍 Testing vocabulary...")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/vocabulary", headers=headers)
    
    if response.status_code == 200:
        vocab = response.json()
        print(f"✅ Found {len(vocab)} vocabulary item(s)")
        if vocab:
            print(f"   Top word: {vocab[0]['word']} (seen {vocab[0]['count']} times)")
    else:
        print(f"❌ Failed: {response.status_code}")


def main():
    print("=" * 60)
    print("🚀 Translation Learning API - Test Suite")
    print("=" * 60)
    print()
    
    try:
        # Test health
        test_health()
        
        # Register/login and get token
        token = test_register_and_login()
        if not token:
            print("❌ Cannot continue without token")
            return
        
        # Test other endpoints
        test_translations(token)
        test_weekly_summary(token)
        test_vocabulary(token)
        
        print("\n" + "=" * 60)
        print("🎉 All tests completed!")
        print("=" * 60)
        
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: Cannot connect to API")
        print("   Make sure the server is running:")
        print("   uvicorn main:app --reload")
    except Exception as e:
        print(f"\n❌ ERROR: {e}")


if __name__ == "__main__":
    main()

