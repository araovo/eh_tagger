const eHentaiSearchUrl = "https://e-hentai.org/?";
const exHentaiSearchUrl = "https://exhentai.org/?";
const eHentaiApiUrl = 'https://api.e-hentai.org/api.php';

const languageMap = {
  'Chinese': 'chinese',
  'chinese': 'chinese',
  '中国語': 'chinese',
  '中国翻訳': 'chinese',
  '中国語翻訳': 'chinese',
  'Japanese': 'japanese',
  '日語': 'japanese',
  'English': 'english',
  '英訳': 'english',
  'Spanish': 'spanish',
  'French': 'french',
  'Russian': 'russian',
};

const otherMap = {
  'Digital': 'digital',
  'DL版': 'digital',
  'Full Color': 'full color',
  '全彩': 'full color',
  'Uncensored': 'uncensored',
  'Decensored': 'uncensored',
  '無修正': 'uncensored',
};

const calibreLanguageMap = {
  '汉语': '中文',
  '韩语': '朝鲜语',
  '日语': '日语',
  '英语': '英语',
  '俄语': '俄语'
};

const calibreLanguageCodeMap = {
  '中文': 'zh',
  '朝鲜语': 'ko',
  '日语': 'ja',
  '英语': 'en',
  '俄语': 'ru'
};

const userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
const httpTimeout = Duration(seconds: 2);
const retries = 5;
const retryDelays = [
  Duration(seconds: 1),
  Duration(seconds: 1),
  Duration(seconds: 1)
];
const downloadStartSuffix = '?start=1';
const downloadThreshold = 9;
