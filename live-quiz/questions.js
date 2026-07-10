// Shared question-set loading for host.html and join.html.
// Relies on the global `jsyaml` from the cdnjs <script> tag both pages load
// before this module runs.

const MODULE_TESTBANK_FILES = {
  concepts: 'concepts-testbank.yaml',
  frameworks: 'frameworks-testbank.yaml',
  'skills-concepts': 'skills-concepts-testbank.yaml',
};

const yamlCache = {};
async function fetchYaml(filename) {
  if (!yamlCache[filename]) {
    const res = await fetch(`../data/${filename}`);
    if (!res.ok) throw new Error(`Could not load ${filename}`);
    yamlCache[filename] = jsyaml.load(await res.text());
  }
  return yamlCache[filename];
}

export async function loadManifest() {
  return (await fetchYaml('live-quiz-sets.yaml')).sets;
}

// `def` is one entry from live-quiz-sets.yaml, one of two shapes:
//  - { label, source, section? }               — a flat live-quiz-shaped file
//  - { label, classPlan, section? }             — live from class-plans.yaml +
//    the KOA testbank files, same data the self-paced Class Player generates
//    its own recap from, fetched fresh every time (never a stale snapshot).
export async function loadQuestionSet(def) {
  if (def.classPlan) return loadFromClassPlan(def);

  const data = await fetchYaml(def.source);
  return { title: data.title || def.label, questions: data.questions };
}

async function loadFromClassPlan(def) {
  const plans = await fetchYaml('class-plans.yaml');
  const plan = plans.find((p) => p.id === def.classPlan);
  if (!plan) throw new Error(`Class plan "${def.classPlan}" not found`);

  let includes;
  if (def.section) {
    const section = (plan.sections || []).find((s) => s.name === def.section);
    if (!section) throw new Error(`Section "${def.section}" not found in class plan "${def.classPlan}"`);
    includes = section.includes;
  } else {
    includes = plan.includes || (plan.sections || []).flatMap((s) => s.includes);
  }

  const questions = [];
  for (const inc of includes || []) {
    const testbankFile = MODULE_TESTBANK_FILES[inc.module];
    if (!testbankFile) throw new Error(`Unknown module "${inc.module}"`);
    const testbank = await fetchYaml(testbankFile);

    const blocks = testbank
      .filter((b) => b.id === inc.id)
      .sort((a, b) => (a.koa === b.koa ? 0 : a.koa === 'K' ? -1 : 1)); // K before A

    for (const block of blocks) {
      for (const q of block.questions || []) {
        if (!q.options || q.answer === undefined) continue; // skip written-only questions
        questions.push({
          question: q.question,
          options: q.options,
          answer: q.answer,
          explanation: q.explanation,
        });
      }
    }
  }
  return { title: def.label, questions };
}
