const helloEl = document.getElementById('hello');
const listEl = document.getElementById('task-list');
const formEl = document.getElementById('add-form');
const inputEl = document.getElementById('new-task');

async function loadHello() {
  try {
    const res = await fetch('/api/hello');
    const data = await res.json();
    helloEl.textContent = `${data.message} (servi par le pod ${data.pod})`;
  } catch (err) {
    helloEl.textContent = 'Impossible de contacter le backend.';
  }
}

async function loadTasks() {
  const res = await fetch('/api/tasks');
  const tasks = await res.json();
  listEl.innerHTML = '';
  tasks.forEach(renderTask);
}

function renderTask(task) {
  const li = document.createElement('li');
  li.className = task.done ? 'done' : '';

  const span = document.createElement('span');
  span.textContent = task.text;
  span.addEventListener('click', () => toggleTask(task.id));

  const delBtn = document.createElement('button');
  delBtn.className = 'delete';
  delBtn.textContent = 'Suppr';
  delBtn.addEventListener('click', () => deleteTask(task.id));

  li.appendChild(span);
  li.appendChild(delBtn);
  listEl.appendChild(li);
}

async function toggleTask(id) {
  await fetch(`/api/tasks/${id}/toggle`, { method: 'PUT' });
  loadTasks();
}

async function deleteTask(id) {
  await fetch(`/api/tasks/${id}`, { method: 'DELETE' });
  loadTasks();
}

formEl.addEventListener('submit', async (e) => {
  e.preventDefault();
  const text = inputEl.value.trim();
  if (!text) return;
  await fetch('/api/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });
  inputEl.value = '';
  loadTasks();
});

loadHello();
loadTasks();
