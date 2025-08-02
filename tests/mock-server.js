const express = require('express');
const app = express();
app.use(express.json());

app.post('/repos/:owner/:template_repo/generate', (req, res) => {
  console.log('Mock intercepted: POST /repos/' + req.params.owner + '/' + req.params.template_repo + '/generate');
  console.log('Request body:', JSON.stringify(req.body));
  
  if (req.body.owner && req.body.name && req.body.description && req.body.private !== undefined) {
    res.status(201).json({ message: 'Repository created' });
  } else {
    res.status(422).json({ message: 'Repository creation failed' });
  }
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
