// Shared question-set loading for host.html and join.html.
// Relies on the global `jsyaml` from the cdnjs <script> tag both pages load
// before this module runs.

export async function loadManifest() {
  const res = await fetch('../data/live-quiz-sets.yaml');
  const text = await res.text();
  return jsyaml.load(text).sets;
}

// `def` is one entry from live-quiz-sets.yaml: { label, source, section? }
export async function loadQuestionSet(def) {
  const res = await fetch(`../data/${def.source}`);
  if (!res.ok) throw new Error(`Could not load question set: ${def.source}`);
  const text = await res.text();
  const data = jsyaml.load(text);

  if (!def.section) {
    return { title: data.title || def.label, questions: data.questions };
  }

  const section = (data.sections || []).find((s) => s.section === def.section);
  if (!section) throw new Error(`Section "${def.section}" not found in ${def.source}`);

  const questions = [];
  for (const topic of section.topics || []) {
    for (const block of topic.recap_questions || []) {
      for (const q of block.questions || []) {
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
