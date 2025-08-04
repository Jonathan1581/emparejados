package com.example.emparejados;

import android.os.Bundle;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private TextView nameText;
    private ImageView photo;
    private Button likeBtn, skipBtn;

    private final String[] names = {"Ana, 24", "Luis, 28", "Camila, 22"};
    private final int[] images = {R.drawable.profile1, R.drawable.profile2, R.drawable.profile3};
    private int currentIndex = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        nameText = findViewById(R.id.nameText);
        photo = findViewById(R.id.profileImage);
        likeBtn = findViewById(R.id.likeButton);
        skipBtn = findViewById(R.id.skipButton);

        loadProfile();

        likeBtn.setOnClickListener(v -> nextProfile());
        skipBtn.setOnClickListener(v -> nextProfile());
    }

    private void loadProfile() {
        if (currentIndex < names.length) {
            nameText.setText(names[currentIndex]);
            photo.setImageResource(images[currentIndex]);
        } else {
            nameText.setText("¡No hay más personas por mostrar!");
            photo.setImageResource(R.drawable.profile1);
            likeBtn.setEnabled(false);
            skipBtn.setEnabled(false);
        }
    }

    private void nextProfile() {
        currentIndex++;
        loadProfile();
    }
}