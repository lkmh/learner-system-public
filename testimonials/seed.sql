-- Placeholder testimonials to launch the wall with before real ones come in.
-- Run once after schema.sql. These are clearly fictional — replace or delete
-- them (Dashboard > Table Editor > testimonials) as real submissions arrive,
-- or just leave the good ones mixed in.

insert into testimonials (name, title, company, class_attended, stars, quote, approved) values
(
  'Priya Nandakumar',
  'Senior Product Manager',
  'Northwind Analytics',
  'GenAI and Prompt Engineering for Professionals',
  5,
  'I went in thinking prompting was just typing nicely worded questions. The framework section alone changed how my whole team writes internal tools — we cut a week of back-and-forth with our AI vendor down to an afternoon.',
  true
),
(
  'Marcus Webb',
  'Customer Success Lead',
  'Fairbank & Cole',
  'GenAI and Prompt Engineering for Professionals',
  5,
  'The hallucination section should be mandatory for anyone shipping an AI feature. I finally understand why our chatbot confidently made up a refund policy, and how to stop it from happening again.',
  true
),
(
  'Aiko Tanaka',
  'Operations Director',
  'Meridian Logistics',
  'GenAI and Prompt Engineering for Professionals',
  4,
  'Genuinely useful, hands-on, no fluff. I''d have liked a bit more time on the RAG section, but everything I did learn I used the same week.',
  true
),
(
  'Daniel Osei',
  'Marketing Manager',
  'Kindle & Rowe',
  'GenAI and Prompt Engineering for Professionals',
  5,
  'Best training I''ve sat through in years, and I''ve sat through a lot of them. The live quiz at the end turned what''s usually a nap-inducing recap into the most competitive twenty minutes of the day.',
  true
),
(
  'Sofia Reyes',
  'Head of Support Operations',
  'Bramblewood Health',
  'GenAI and Prompt Engineering for Professionals',
  5,
  'I came in skeptical that "prompt engineering" was a real skill and not just a buzzword. Left with an actual framework I use every day, and a much healthier skepticism about anything an LLM tells me with total confidence.',
  true
),
(
  'James Okonkwo',
  'IT Business Partner',
  'Aldergate Financial',
  'GenAI and Prompt Engineering for Professionals',
  5,
  'The tokens and context window explanations finally made our API costs make sense. I''ve since rewritten two of our internal prompts and cut our monthly bill noticeably.',
  true
);
