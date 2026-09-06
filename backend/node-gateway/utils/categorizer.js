const categories = [
  'Roads & Transport',
  'Water & Sewage',
  'Electricity & Lighting',
  'Waste & Sanitation',
  'Public Hazards & Safety',
  'Public Infrastructure',
];

const keywordGroups = {
  'Roads & Transport': [
    'road', 'pothole', 'traffic', 'bus', 'train', 'bridge', 'street', 'transport',
  ],
  'Water & Sewage': [
    'water', 'sewage', 'sewer', 'drain', 'flood', 'leak', 'pipeline', 'tap',
  ],
  'Electricity & Lighting': [
    'electric', 'power', 'outage', 'light', 'lighting', 'streetlight', 'transformer',
  ],
  'Waste & Sanitation': [
    'waste', 'garbage', 'trash', 'rubbish', 'sanitation', 'toilet', 'litter',
  ],
  'Public Hazards & Safety': [
    'hazard', 'danger', 'unsafe', 'accident', 'fire', 'collapse', 'crime', 'safety',
  ],
  'Public Infrastructure': [
    'building', 'park', 'bench', 'sidewalk', 'infrastructure', 'facility',
  ],
};

function keywordCategory(description) {
  const text = String(description || '').toLowerCase();
  let bestCategory = 'Public Infrastructure';
  let bestScore = 0;

  for (const category of categories) {
    const score = keywordGroups[category].reduce(
      (total, keyword) => total + (text.includes(keyword) ? 1 : 0),
      0,
    );
    if (score > bestScore) {
      bestCategory = category;
      bestScore = score;
    }
  }
  return bestCategory;
}

async function categorizeReport(description) {
  try {
    const response = await fetch('http://127.0.0.1:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(15000),
      body: JSON.stringify({
        model: 'llama3.2:1b',
        stream: false,
        format: 'json',
        prompt: "Classify this issue into EXACTLY ONE category: ['Roads & Transport', 'Water & Sewage', 'Electricity & Lighting', 'Waste & Sanitation', 'Public Hazards & Safety', 'Public Infrastructure']. Return JSON: {\"category\": \"...\"}. Issue: " + String(description || ''),
      }),
    });
    if (!response.ok) throw new Error(`Ollama returned HTTP ${response.status}`);
    const data = await response.json();
    const parsed = JSON.parse(data.response);
    return categories.includes(parsed.category)
      ? parsed.category
      : keywordCategory(description);
  } catch (_) {
    return keywordCategory(description);
  }
}

async function generateReportSummary(rawText) {
  console.log("[Ollama Summary Start]", rawText);
  try {
    const response = await fetch('http://127.0.0.1:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(15000),
      body: JSON.stringify({
        model: 'llama3.2:1b',
        stream: false,
        format: 'json',
        prompt: 'Summarize this civic issue into 1 professional sentence. Return valid JSON like {"summary": "..."}. Issue: ' + String(rawText || ''),
      }),
    });
    if (!response.ok) throw new Error(`Ollama returned HTTP ${response.status}`);
    const data = await response.json();
    const parsed = JSON.parse(data.response);
    return parsed.summary;
  } catch (err) {
    console.error("[Ollama Summary Error]", err);
    return rawText;
  }
}

module.exports = { categorizeReport, generateReportSummary };