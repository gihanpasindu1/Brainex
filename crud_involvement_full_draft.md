# 1.9 CRUD Operations - Individual Involvement

The development of the Brainex platform followed a collaborative approach where every team member was responsible for implementing the core CRUD (Create, Read, Update, Delete) operations for their respective feature modules. This section outlines the specific contributions, code justifications, and proofs of involvement for each developer.

---

### 1.9.1 Wenuja - Short Note Generation & Management
**Role:** Backend Developer for Academic Summarization
**Primary CRUD Functionality:** Managing the lifecycle of generated short notes, including saving summaries to the database, retrieving them for the student, and allowing the deletion of outdated notes.
**Justification:** Wenuja ensured that students could efficiently store their AI-summarized content. By implementing these CRUD routes, he enabled a "personal revision library" within the system, reducing the need for students to re-generate the same notes multiple times.

**Code Proof:**
*(Add Screenshot 1.9.1: Snippet from [short_notes.py](file:///c:/Users/User/Desktop/SDGP/backend/app/routes/short_notes.py) showing the POST and GET routes for note management.)*

---

### 1.9.2 Malinga - Study Plan Personalization
**Role:** Backend Developer for Planning Services
**Primary CRUD Functionality:** Developing the logic for creating, reading, and updating personalized study plans. This includes modifying the user's schedule based on progress.
**Justification:** Malinga's contribution was critical for the "long-term study goal" aspect of Brainex. His CRUD operations allowed students to not only generate a plan but also refine it as their examination dates approached, ensuring the system remained adaptable to changing user needs.

**Code Proof:**
*(Add Screenshot 1.9.2: Snippet from [planner.py](file:///c:/Users/User/Desktop/SDGP/backend/app/routes/planner.py) showing the study plan saving and update logic.)*

---

### 1.9.3 Ravindu - User Profile & Identity
**Role:** Full-Stack Developer for User Management
**Primary CRUD Functionality:** Implementing the profile page where users can Create their account identity, Read their personal information, and Update details like their name or profile image.
**Justification:** Ravindu built the entry point for every user. His work on the profile CRUDs was essential for establishing a personalized experience and ensuring that all other system features (like rewards and history) were correctly mapped to a unique user identity.

**Code Proof:**
*(Add Screenshot 1.9.3: Snippet from [users.py](file:///c:/Users/User/Desktop/SDGP/backend/app/routes/users.py) or the `ProfileScreen` UI code showing the data binding.)*

---

### 1.9.4 Gihan - Chatbot Interaction History
**Role:** AI Services & Interaction Developer
**Primary CRUD Functionality:** Managing the persistent history of chatbot interactions. This involves saving chat messages to the database and retrieving them so the user can continue previous learning sessions.
**Justification:** Gihan's work on chat history CRUDs ensured that user interactions with the AI weren't lost when closing the app. This persistence is foundational for a "learning buddy" experience where the system "remembers" previous queries.

**Code Proof:**
*(Add Screenshot 1.9.4: Snippet from [chat.py](file:///c:/Users/User/Desktop/SDGP/backend/app/routes/chat.py) or [arcee_service.py](file:///c:/Users/User/Desktop/SDGP/backend/app/services/arcee_service.py) showing the database interaction for chat history.)*

---

### 1.9.5 Akaas - Model Paper Management
**Role:** Academic Content & Assessment Developer
**Primary CRUD Functionality:** Implementing the CRUD operations for AI-generated model papers. This includes the ability to generate a paper (Create), list existing papers (Read), and manage the storage of MCQ data.
**Justification:** Akaas allowed Brainex to serve as an assessment tool. By creating a structured way to store and retrieve generated papers, he ensured that students could retake their generated tests later, facilitating continuous self-evaluation.

**Code Proof:**
*(Add Screenshot 1.9.5: Snippet from [modelpapers.py](file:///c:/Users/User/Desktop/SDGP/backend/app/routes/modelpapers.py) showing the retrieval and saving of MCQ sets.)*

---

### 1.9.6 Raminthi - Leaderboard & Challenge Analytics
**Role:** Community & Gamification Developer
**Primary CRUD Functionality:** Managing the record-keeping for the leaderboard and student scores. This includes updating scores after challenges (Update) and retrieving top-performer rankings (Read).
**Justification:** Raminthi was responsible for the social and competitive aspect of the platform. Her implementation of the leaderboard CRUD operations was vital for driving student engagement and providing a clear metric of progress relative to the rest of the student community.

**Code Proof:**
*(Add Screenshot 1.9.6: Snippet from [global_challenges.py](file:///c:/Users/User/Desktop/SDGP/backend/app/routes/global_challenges.py) or `leaderboard_service` showing the score update logic.)*
