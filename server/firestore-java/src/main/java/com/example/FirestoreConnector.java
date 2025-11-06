package com.example;

import com.google.api.core.ApiFuture;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.FirestoreOptions;
import com.google.cloud.firestore.ListenerRegistration;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

public class FirestoreConnector {

    public static Firestore initializeFirestore(String serviceAccountPath, String projectId) throws IOException {
        FileInputStream serviceAccount = new FileInputStream(serviceAccountPath);
        GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount);

        FirestoreOptions options = FirestoreOptions.newBuilder()
                .setCredentials(credentials)
                .setProjectId(projectId)
                .build();

        return options.getService();
    }

    public static void main(String[] args) throws IOException, ExecutionException, InterruptedException {
        if (args.length < 2) {
            System.err.println("Usage: java -jar firestore-java-sample.jar <serviceAccount.json> <projectId>");
            System.exit(1);
        }
        String saPath = args[0];
        String projectId = args[1];

        Firestore db = initializeFirestore(saPath, projectId);
        System.out.println("Firestore initialized successfully for project: " + projectId);

        // Simple write
        CollectionReference users = db.collection("users");
        DocumentReference docRef = users.document("sample-user");
        Map<String, Object> data = new HashMap<>();
        data.put("email", "sample@domain.com");
        data.put("displayName", "Sample User");

        ApiFuture<WriteResult> writeResult = docRef.set(data);
        System.out.println("Wrote document at: " + writeResult.get().getUpdateTime());

        // Simple read
        ApiFuture<QuerySnapshot> query = users.get();
        QuerySnapshot querySnapshot = query.get();
        for (QueryDocumentSnapshot document : querySnapshot.getDocuments()) {
            System.out.println("User doc: " + document.getId() + " => " + document.getData());
        }

        // Listener example (keeps JVM running for demo)
        System.out.println("Adding snapshot listener to 'users' collection. Modify documents in console to see updates.");
        ListenerRegistration reg = users.addSnapshotListener((snapshots, e) -> {
            if (e != null) {
                System.err.println("Listen failed: " + e);
                return;
            }
            if (snapshots != null) {
                System.out.println("Received users snapshot with " + snapshots.size() + " docs");
            }
        });

        // Keep running for demo purposes
        System.out.println("Press Ctrl+C to exit");
        try {
            Thread.sleep(Long.MAX_VALUE);
        } catch (InterruptedException ie) {
            reg.remove();
        }
    }
}
