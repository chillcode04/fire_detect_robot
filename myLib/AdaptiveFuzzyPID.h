#ifndef __AdaptiveFuzzyPID_H
#define __AdaptiveFuzzyPID_H

#include <math.h>
#include <stdint.h>

#define FUZZY_SETS 7

// Toa do tâm
#define FUZZY_CENTROID_NL    -3.0f
#define FUZZY_CENTROID_NM    -2.0f
#define FUZZY_CENTROID_NS    -1.0f
#define FUZZY_CENTROID_ZE     0.0f
#define FUZZY_CENTROID_PS     1.0f
#define FUZZY_CENTROID_PM     2.0f
#define FUZZY_CENTROID_PL     3.0f

typedef struct {
    float eMax;
    float deMax;
    float scaleKp;
    float scaleKi;
    float scaleKd;
    
    float mu_e[7];
    float mu_de[7];
    
    float mu_out_kp[7];
    float mu_out_ki[7];
    float mu_out_kd[7];
    
    const int8_t *ruleTableKp;
    const int8_t *ruleTableKi;
    const int8_t *ruleTableKd;
    
    float deltaKp;
    float deltaKi;
    float deltaKd;
} FuzzyTuner;

// --- Prototypes ---
void Fuzzy_Init(FuzzyTuner *self, float eMax, float deMax, float sKp, float sKi, float sKd, 
                const int8_t *tableKp, const int8_t *tableKi, const int8_t *tableKd);
void Fuzzify(float input, float* mu);

float Triangle_MF(float x, float a, float b, float c);

void Fuzzy_Compute(FuzzyTuner *self, float error, float dError);

void Fuzzy_Reset(FuzzyTuner *self);

#endif