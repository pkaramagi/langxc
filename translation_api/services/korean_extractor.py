"""
Korean vocabulary extraction service using KoNLPy.
Extracts meaningful words from Korean text.
"""
from typing import List, Set
import re

try:
    from konlpy.tag import Okt
    KONLPY_AVAILABLE = True
except ImportError:
    KONLPY_AVAILABLE = False
    print("Warning: KoNLPy not available. Using fallback word extraction.")


class KoreanExtractor:
    def __init__(self):
        if KONLPY_AVAILABLE:
            self.okt = Okt()
        else:
            self.okt = None
    
    def extract_words(self, text: str, min_length: int = 2) -> List[str]:
        """
        Extract meaningful Korean words from text.
        
        Args:
            text: Korean text to extract words from
            min_length: Minimum word length to include
            
        Returns:
            List of extracted words
        """
        if not text or not text.strip():
            return []
        
        if self.okt:
            return self._extract_with_konlpy(text, min_length)
        else:
            return self._extract_fallback(text, min_length)
    
    def _extract_with_konlpy(self, text: str, min_length: int) -> List[str]:
        """Extract words using KoNLPy morphological analysis."""
        try:
            # Use morphs() to get basic morphemes
            # Filter for nouns, verbs, adjectives (meaningful words)
            pos_tags = self.okt.pos(text, stem=True)
            
            words = []
            for word, pos in pos_tags:
                # Keep nouns, verbs, adjectives
                if pos in ['Noun', 'Verb', 'Adjective'] and len(word) >= min_length:
                    # Filter out common particles and very short words
                    if self._is_meaningful_word(word):
                        words.append(word)
            
            return list(set(words))  # Remove duplicates
        except Exception as e:
            print(f"KoNLPy extraction failed: {e}")
            return self._extract_fallback(text, min_length)
    
    def _extract_fallback(self, text: str, min_length: int) -> List[str]:
        """Fallback extraction using simple regex (less accurate)."""
        # Extract sequences of Korean characters
        korean_pattern = re.compile(r'[가-힣]+')
        words = korean_pattern.findall(text)
        
        # Filter by length and remove duplicates
        meaningful_words = [
            word for word in words 
            if len(word) >= min_length and self._is_meaningful_word(word)
        ]
        
        return list(set(meaningful_words))
    
    def _is_meaningful_word(self, word: str) -> bool:
        """Check if word is meaningful (not a common particle or filler)."""
        # Common Korean particles and fillers to exclude
        exclude = {
            '이', '가', '을', '를', '은', '는', '의', '에', '와', '과',
            '도', '만', '부터', '까지', '한테', '께', '로', '으로',
            '네', '요', '어', '아', '지', '게', '고',
        }
        return word not in exclude
    
    def extract_unique_words(self, texts: List[str], min_length: int = 2) -> Set[str]:
        """Extract unique words from multiple texts."""
        all_words = set()
        for text in texts:
            words = self.extract_words(text, min_length)
            all_words.update(words)
        return all_words


# Singleton instance
korean_extractor = KoreanExtractor()

