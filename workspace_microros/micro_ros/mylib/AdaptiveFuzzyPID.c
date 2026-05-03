#include "AdaptiveFuzzyPID.h"


static const float centroids[7] = {
    FUZZY_CENTROID_NL, FUZZY_CENTROID_NM, FUZZY_CENTROID_NS,
    FUZZY_CENTROID_ZE, FUZZY_CENTROID_PS, FUZZY_CENTROID_PM,
    FUZZY_CENTROID_PL
};

 float Triangle_MF(float x, float a, float b, float c) {
    if (x <= a || x >= c) return 0.0f;
    if (x == b) return 1.0f;
    if (x > a && x < b) return (x - a) / (b - a);
    return (c - x) / (c - b);
}

 void Fuzzify(float input, float* mu) {
    // input n?m trong d?i [-3, 3]
    mu[0] = Triangle_MF(input, -4.0f, -3.0f, -2.0f); // NL
    mu[1] = Triangle_MF(input, -3.0f, -2.0f, -1.0f); // NM
    mu[2] = Triangle_MF(input, -2.0f, -1.0f,  0.0f); // NS
    mu[3] = Triangle_MF(input, -1.0f,  0.0f,  1.0f); // ZE
    mu[4] = Triangle_MF(input,  0.0f,  1.0f,  2.0f); // PS
    mu[5] = Triangle_MF(input,  1.0f,  2.0f,  3.0f); // PM
    mu[6] = Triangle_MF(input,  2.0f,  3.0f,  4.0f); // PL
}

void Fuzzy_Init(FuzzyTuner *self, float eMax, float deMax, float sKp, float sKi, float sKd,
                const int8_t *tableKp, const int8_t *tableKi, const int8_t *tableKd) {
    self->eMax = eMax;
    self->deMax = deMax;
    self->scaleKp = sKp;
    self->scaleKi = sKi;
    self->scaleKd = sKd;
    self->ruleTableKp = tableKp;
    self->ruleTableKi = tableKi;
    self->ruleTableKd = tableKd;

    //Xoa du lieu ban dau
    for(int i=0; i<7; i++) {
        self->mu_out_kp[i] = 0; self->mu_out_ki[i] = 0; self->mu_out_kd[i] = 0;
    }
}

void Fuzzy_Compute(FuzzyTuner *self, float error, float dError) {
    // 1. Chuan hoa dau vao (Normalization)
    float norm_e = (error / self->eMax) * 3.0f;
    float norm_de = (dError / self->deMax) * 3.0f;

    // Gioi han trong dai [-3, 3]
    if(norm_e > 3.0f) norm_e = 3.0f; else if(norm_e < -3.0f) norm_e = -3.0f;
    if(norm_de > 3.0f) norm_de = 3.0f; else if(norm_de < -3.0f) norm_de = -3.0f;

    // 2. Mo hoa (Fuzzification)
    Fuzzify(norm_e, self->mu_e);
    Fuzzify(norm_de, self->mu_de);

    // Xóa ket qua hop thanh cu
    for(int i = 0; i < 7; i++) {
        self->mu_out_kp[i] = 0.0f; self->mu_out_ki[i] = 0.0f; self->mu_out_kd[i] = 0.0f;
    }

    // 3. Suy luan Mamdani Max-Min (7*7)
    for (int i = 0; i < 7; i++) {
        if (self->mu_e[i] > 0) {
            for (int j = 0; j < 7; j++) {
                if (self->mu_de[j] > 0) {
                    // Min (Cat ngon)
                    float weight = (self->mu_e[i] < self->mu_de[j]) ? self->mu_e[i] : self->mu_de[j];

                    // Tra bang luat
                    int outKp = self->ruleTableKp[i * 7 + j] + 3;
                    int outKi = self->ruleTableKi[i * 7 + j] + 3;
                    int outKd = self->ruleTableKd[i * 7 + j] + 3;

                    // Buoc Max (Hop thành)
                    if (weight > self->mu_out_kp[outKp]) self->mu_out_kp[outKp] = weight;
                    if (weight > self->mu_out_ki[outKi]) self->mu_out_ki[outKi] = weight;
                    if (weight > self->mu_out_kd[outKd]) self->mu_out_kd[outKd] = weight;
                }
            }
        }
    }

    // 4. Giai mp Trong tâm (Centroid Defuzzification)
    float sumMuKp = 0, sumNumKp = 0;
    float sumMuKi = 0, sumNumKi = 0;
    float sumMuKd = 0, sumNumKd = 0;

    for (int i = 0; i < 7; i++) {
        sumNumKp += self->mu_out_kp[i] * centroids[i]; sumMuKp += self->mu_out_kp[i];
        sumNumKi += self->mu_out_ki[i] * centroids[i]; sumMuKi += self->mu_out_ki[i];
        sumNumKd += self->mu_out_kd[i] * centroids[i]; sumMuKd += self->mu_out_kd[i];
    }

    // Ket qua cuoi cùng = (Trong tâm) * Scale
    self->deltaKp = (sumMuKp > 0) ? (sumNumKp / sumMuKp) * self->scaleKp : 0;
    self->deltaKi = (sumMuKi > 0) ? (sumNumKi / sumMuKi) * self->scaleKi : 0;
    self->deltaKd = (sumMuKd > 0) ? (sumNumKd / sumMuKd) * self->scaleKd : 0;
}
