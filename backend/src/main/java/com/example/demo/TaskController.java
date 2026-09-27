package com.example.demo;

import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class TaskController {

    private final Map<Long, Task> tasks = new ConcurrentHashMap<>();
    private final AtomicLong idSeq = new AtomicLong(1);

    public TaskController() {
        long id1 = idSeq.getAndIncrement();
        tasks.put(id1, new Task(id1, "Déployer le cluster Kubernetes", true));
        long id2 = idSeq.getAndIncrement();
        tasks.put(id2, new Task(id2, "Déployer cette application dessus", false));
    }

    @GetMapping("/hello")
    public Map<String, String> hello() {
        String podName = System.getenv().getOrDefault("HOSTNAME", "unknown-pod");
        return Map.of(
                "message", "Bonjour depuis le backend Java !",
                "pod", podName
        );
    }

    @GetMapping("/tasks")
    public List<Task> listTasks() {
        return tasks.values().stream()
                .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                .toList();
    }

    @PostMapping("/tasks")
    public Task addTask(@RequestBody Map<String, String> body) {
        long id = idSeq.getAndIncrement();
        Task task = new Task(id, body.getOrDefault("text", ""), false);
        tasks.put(id, task);
        return task;
    }

    @PutMapping("/tasks/{id}/toggle")
    public Task toggleTask(@PathVariable long id) {
        Task task = tasks.get(id);
        if (task != null) {
            task.setDone(!task.isDone());
        }
        return task;
    }

    @DeleteMapping("/tasks/{id}")
    public void deleteTask(@PathVariable long id) {
        tasks.remove(id);
    }
}
