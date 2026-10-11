/// Canonical Taxonomy Seed Data for NEET & JEE
/// Aligns with the 83 existing database chapters in `public.chapters`
class CanonicalTaxonomyData {
  static List<Map<String, dynamic>> getSeedChaptersForSubject(String exam, String subject) {
    final sUpper = subject.toUpperCase().trim();

    if (sUpper == 'PHYSICS') {
      return neetPhysicsChapters;
    } else if (sUpper == 'CHEMISTRY') {
      return neetChemistryChapters;
    } else if (sUpper == 'BIOLOGY' || sUpper.contains('BIO') || sUpper.contains('BOTAN') || sUpper.contains('ZOOL')) {
      return neetBiologyChapters;
    } else if (sUpper.contains('MATH')) {
      return jeeMathChapters;
    }
    return [];
  }

  static final List<Map<String, dynamic>> neetPhysicsChapters = [
    {
      'name': '1. Units & Measurements',
      'code': 'UNITS_&_MEASUREMENTS',
      'topicsList': [
        {'id': 't_phy_1_1', 'name': '1.1 Physical Quantities, SI Units & Standards', 'code': 'TOPIC_UNITS_SI', 'status': 'Active'},
        {'id': 't_phy_1_2', 'name': '1.2 Significant Figures, Rounding Off & Error Analysis', 'code': 'TOPIC_ERRORS', 'status': 'Active'},
        {'id': 't_phy_1_3', 'name': '1.3 Dimensional Analysis & Formula Derivation', 'code': 'TOPIC_DIMENSIONS', 'status': 'Active'},
        {'id': 't_phy_1_4', 'name': '1.4 Measuring Instruments (Vernier Calipers & Screw Gauge)', 'code': 'TOPIC_INSTRUMENTS', 'status': 'Active'},
      ],
    },
    {
      'name': '2. Motion 1D',
      'code': 'MOTION_1D',
      'topicsList': [
        {'id': 't_phy_2_1', 'name': '2.1 Frame of Reference, Distance & Displacement', 'code': 'TOPIC_1D_FRAME', 'status': 'Active'},
        {'id': 't_phy_2_2', 'name': '2.2 Speed, Velocity & Instantaneous Acceleration', 'code': 'TOPIC_1D_VELOCITY', 'status': 'Active'},
        {'id': 't_phy_2_3', 'name': '2.3 Equations of Motion Under Gravity', 'code': 'TOPIC_1D_GRAVITY', 'status': 'Active'},
        {'id': 't_phy_2_4', 'name': '2.4 Graphical Analysis (x-t, v-t, a-t Graphs)', 'code': 'TOPIC_1D_GRAPHS', 'status': 'Active'},
      ],
    },
    {
      'name': '3. Motion 2D',
      'code': 'MOTION_2D',
      'topicsList': [
        {'id': 't_phy_3_1', 'name': '3.1 Vectors: Components, Addition & Dot/Cross Products', 'code': 'TOPIC_VECTORS', 'status': 'Active'},
        {'id': 't_phy_3_2', 'name': '3.2 Projectile Motion: Range, Time of Flight & Max Height', 'code': 'TOPIC_PROJECTILE', 'status': 'Active'},
        {'id': 't_phy_3_3', 'name': '3.3 Uniform Circular Motion & Centripetal Acceleration', 'code': 'TOPIC_CIRCULAR', 'status': 'Active'},
        {'id': 't_phy_3_4', 'name': '3.4 Relative Velocity in Two Dimensions', 'code': 'TOPIC_RELATIVE_2D', 'status': 'Active'},
      ],
    },
    {
      'name': '4. Laws of Motion',
      'code': 'LAWS_OF_MOTION',
      'topicsList': [
        {'id': 't_phy_4_1', 'name': '4.1 Newton\'s Laws of Motion & Momentum', 'code': 'TOPIC_NLM', 'status': 'Active'},
        {'id': 't_phy_4_2', 'name': '4.2 Equilibrium of Concurrent Forces & FBD', 'code': 'TOPIC_FBD', 'status': 'Active'},
        {'id': 't_phy_4_3', 'name': '4.3 Static, Kinetic and Rolling Friction', 'code': 'TOPIC_FRICTION', 'status': 'Active'},
        {'id': 't_phy_4_4', 'name': '4.4 Dynamics of Circular Motion & Banking of Roads', 'code': 'TOPIC_BANKING', 'status': 'Active'},
      ],
    },
    {
      'name': '5. WPE (Work, Power & Energy)',
      'code': 'WPE_(WORK,_POWER_&_ENERGY)',
      'topicsList': [
        {'id': 't_phy_5_1', 'name': '5.1 Work Done by Constant & Variable Forces', 'code': 'TOPIC_WORK_DONE', 'status': 'Active'},
        {'id': 't_phy_5_2', 'name': '5.2 Kinetic Energy & Work-Energy Theorem', 'code': 'TOPIC_WORK_ENERGY_THM', 'status': 'Active'},
        {'id': 't_phy_5_3', 'name': '5.3 Potential Energy & Conservation of Mechanical Energy', 'code': 'TOPIC_MECH_ENERGY', 'status': 'Active'},
        {'id': 't_phy_5_4', 'name': '5.4 Power, Collisions in 1D & 2D', 'code': 'TOPIC_COLLISIONS', 'status': 'Active'},
      ],
    },
    {
      'name': '6. System of Particles & Rotation',
      'code': 'SYSTEM_OF_PARTICLES_&_ROTATION',
      'topicsList': [
        {'id': 't_phy_6_1', 'name': '6.1 Centre of Mass & Conservation of Linear Momentum', 'code': 'TOPIC_COM', 'status': 'Active'},
        {'id': 't_phy_6_2', 'name': '6.2 Torque, Angular Momentum & Conservation', 'code': 'TOPIC_ANGULAR_MOM', 'status': 'Active'},
        {'id': 't_phy_6_3', 'name': '6.3 Moment of Inertia & Parallel/Perpendicular Axes', 'code': 'TOPIC_MOI', 'status': 'Active'},
        {'id': 't_phy_6_4', 'name': '6.4 Pure Rolling Motion & Kinematics on Incline', 'code': 'TOPIC_ROLLING', 'status': 'Active'},
      ],
    },
    {
      'name': '7. Gravitation',
      'code': 'GRAVITATION',
      'topicsList': [
        {'id': 't_phy_7_1', 'name': '7.1 Universal Law of Gravitation & Kepler\'s Laws', 'code': 'TOPIC_KEPLER', 'status': 'Active'},
        {'id': 't_phy_7_2', 'name': '7.2 Acceleration Due to Gravity & Its Variations', 'code': 'TOPIC_GRAVITY_VAR', 'status': 'Active'},
        {'id': 't_phy_7_3', 'name': '7.3 Gravitational Potential Energy & Escape Velocity', 'code': 'TOPIC_ESCAPE_VEL', 'status': 'Active'},
        {'id': 't_phy_7_4', 'name': '7.4 Satellite Motion, Orbital Velocity & Time Period', 'code': 'TOPIC_SATELLITES', 'status': 'Active'},
      ],
    },
    {
      'name': '8. Mechanical Properties of Solids',
      'code': 'MECHANICAL_PROPERTIES_OF_SOLIDS',
      'topicsList': [
        {'id': 't_phy_8_1', 'name': '8.1 Stress, Strain & Hooke\'s Law', 'code': 'TOPIC_STRESS_STRAIN', 'status': 'Active'},
        {'id': 't_phy_8_2', 'name': '8.2 Elastic Moduli: Young\'s, Bulk & Shear Modulus', 'code': 'TOPIC_ELASTIC_MODULI', 'status': 'Active'},
        {'id': 't_phy_8_3', 'name': '8.3 Elastic Potential Energy in Stretched Wire', 'code': 'TOPIC_ELASTIC_ENERGY', 'status': 'Active'},
      ],
    },
    {
      'name': '9. Mechanical Properties of Fluids',
      'code': 'MECHANICAL_PROPERTIES_OF_FLUIDS',
      'topicsList': [
        {'id': 't_phy_9_1', 'name': '9.1 Pascal\'s Law, Atmospheric Pressure & Buoyancy', 'code': 'TOPIC_PASCAL_LAW', 'status': 'Active'},
        {'id': 't_phy_9_2', 'name': '9.2 Viscosity, Stokes\' Law & Terminal Velocity', 'code': 'TOPIC_VISCOSITY', 'status': 'Active'},
        {'id': 't_phy_9_3', 'name': '9.3 Bernoulli\'s Principle & Continuity Equation', 'code': 'TOPIC_BERNOULLI', 'status': 'Active'},
        {'id': 't_phy_9_4', 'name': '9.4 Surface Tension, Surface Energy & Capillarity', 'code': 'TOPIC_SURFACE_TENSION', 'status': 'Active'},
      ],
    },
    {
      'name': '10. Thermal Properties of Matter',
      'code': 'THERMAL_PROPERTIES_OF_MATTER',
      'topicsList': [
        {'id': 't_phy_10_1', 'name': '10.1 Heat, Temperature & Thermal Expansion', 'code': 'TOPIC_THERMAL_EXP', 'status': 'Active'},
        {'id': 't_phy_10_2', 'name': '10.2 Specific Heat Capacity & Principle of Calorimetry', 'code': 'TOPIC_CALORIMETRY', 'status': 'Active'},
        {'id': 't_phy_10_3', 'name': '10.3 Latent Heat & Phase Transformations', 'code': 'TOPIC_LATENT_HEAT', 'status': 'Active'},
        {'id': 't_phy_10_4', 'name': '10.4 Thermal Conduction & Radiation (Stefan, Wien, Newton)', 'code': 'TOPIC_RADIATION', 'status': 'Active'},
      ],
    },
    {
      'name': '11. Thermodynamics',
      'code': 'THERMODYNAMICS',
      'topicsList': [
        {'id': 't_phy_11_1', 'name': '11.1 Zeroth & First Law of Thermodynamics', 'code': 'TOPIC_FIRST_LAW', 'status': 'Active'},
        {'id': 't_phy_11_2', 'name': '11.2 Thermodynamic Processes (Isothermal, Adiabatic, Isobaric)', 'code': 'TOPIC_PROCESSES', 'status': 'Active'},
        {'id': 't_phy_11_3', 'name': '11.3 Work Done in Thermodynamic Processes', 'code': 'TOPIC_WORK_THERMO', 'status': 'Active'},
        {'id': 't_phy_11_4', 'name': '11.4 Second Law of Thermodynamics, Heat Engines & Carnot Cycle', 'code': 'TOPIC_SECOND_LAW', 'status': 'Active'},
      ],
    },
    {
      'name': '12. Kinetic Theory of Gases',
      'code': 'KINETIC_THEORY_OF_GASES',
      'topicsList': [
        {'id': 't_phy_12_1', 'name': '12.1 Equation of State of Perfect Gas & Kinetic Postulates', 'code': 'TOPIC_IDEAL_GAS', 'status': 'Active'},
        {'id': 't_phy_12_2', 'name': '12.2 Pressure Expression & RMS Speed Calculations', 'code': 'TOPIC_RMS_SPEED', 'status': 'Active'},
        {'id': 't_phy_12_3', 'name': '12.3 Degrees of Freedom & Law of Equipartition of Energy', 'code': 'TOPIC_EQUIPARTITION', 'status': 'Active'},
        {'id': 't_phy_12_4', 'name': '12.4 Specific Heats (Cp, Cv) & Mean Free Path', 'code': 'TOPIC_MEAN_FREE_PATH', 'status': 'Active'},
      ],
    },
    {
      'name': '13. Oscillations',
      'code': 'OSCILLATIONS',
      'topicsList': [
        {'id': 't_phy_13_1', 'name': '13.1 Simple Harmonic Motion (SHM) Kinematics', 'code': 'TOPIC_SHM_KINEMATICS', 'status': 'Active'},
        {'id': 't_phy_13_2', 'name': '13.2 Energy in SHM (Kinetic, Potential & Total Energy)', 'code': 'TOPIC_SHM_ENERGY', 'status': 'Active'},
        {'id': 't_phy_13_3', 'name': '13.3 Simple Pendulum & Spring-Mass System Oscillations', 'code': 'TOPIC_PENDULUM', 'status': 'Active'},
        {'id': 't_phy_13_4', 'name': '13.4 Free, Damped & Forced Oscillations, Resonance', 'code': 'TOPIC_DAMPED_SHM', 'status': 'Active'},
      ],
    },
    {
      'name': '14. Waves',
      'code': 'WAVES',
      'topicsList': [
        {'id': 't_phy_14_1', 'name': '14.1 Wave Motion: Transverse & Longitudinal Waves', 'code': 'TOPIC_WAVE_MOTION', 'status': 'Active'},
        {'id': 't_phy_14_2', 'name': '14.2 Speed of Sound & Laplace Correction', 'code': 'TOPIC_SOUND_SPEED', 'status': 'Active'},
        {'id': 't_phy_14_3', 'name': '14.3 Superposition, Standing Waves & Organ Pipes', 'code': 'TOPIC_ORGAN_PIPES', 'status': 'Active'},
        {'id': 't_phy_14_4', 'name': '14.4 Beats & Doppler Effect in Sound', 'code': 'TOPIC_BEATS_DOPPLER', 'status': 'Active'},
      ],
    },
    {
      'name': '15. Electric Charges & Field',
      'code': 'ELECTRIC_CHARGES_&_FIELD',
      'topicsList': [
        {'id': 't_phy_15_1', 'name': '15.1 Coulomb\'s Law & Principle of Superposition', 'code': 'TOPIC_COULOMB', 'status': 'Active'},
        {'id': 't_phy_15_2', 'name': '15.2 Electric Field & Field Lines', 'code': 'TOPIC_E_FIELD', 'status': 'Active'},
        {'id': 't_phy_15_3', 'name': '15.3 Electric Dipole: Field on Axial & Equatorial Lines', 'code': 'TOPIC_DIPOLE', 'status': 'Active'},
        {'id': 't_phy_15_4', 'name': '15.4 Gauss\'s Law & Continuous Charge Distributions', 'code': 'TOPIC_GAUSS_LAW', 'status': 'Active'},
      ],
    },
    {
      'name': '16. Electrostatic Potential & Capacitance',
      'code': 'ELECTROSTATIC_POTENTIAL_&_CAPACITANCE',
      'topicsList': [
        {'id': 't_phy_16_1', 'name': '16.1 Electric Potential & Equipotential Surfaces', 'code': 'TOPIC_POTENTIAL', 'status': 'Active'},
        {'id': 't_phy_16_2', 'name': '16.2 Electrostatic Potential Energy of System of Charges', 'code': 'TOPIC_POT_ENERGY', 'status': 'Active'},
        {'id': 't_phy_16_3', 'name': '16.3 Capacitors & Capacitance with Dielectrics', 'code': 'TOPIC_CAPACITOR_DIELECTRIC', 'status': 'Active'},
        {'id': 't_phy_16_4', 'name': '16.4 Combinations of Capacitors & Energy Stored', 'code': 'TOPIC_CAPACITOR_CIRCUITS', 'status': 'Active'},
      ],
    },
    {
      'name': '17. Current Electricity',
      'code': 'CURRENT_ELECTRICITY',
      'topicsList': [
        {'id': 't_phy_17_1', 'name': '17.1 Electric Current, Drift Velocity & Ohm\'s Law', 'code': 'TOPIC_DRIFT_VELOCITY', 'status': 'Active'},
        {'id': 't_phy_17_2', 'name': '17.2 Resistance, Resistivity & Temperature Coefficient', 'code': 'TOPIC_RESISTANCE', 'status': 'Active'},
        {'id': 't_phy_17_3', 'name': '17.3 Kirchhoff\'s Rules & Complex Circuit Analysis', 'code': 'TOPIC_KIRCHHOFF', 'status': 'Active'},
        {'id': 't_phy_17_4', 'name': '17.4 Cells, EMF, Internal Resistance & Meter Bridge', 'code': 'TOPIC_METER_BRIDGE', 'status': 'Active'},
      ],
    },
    {
      'name': '18. Moving Charges & Magnetism',
      'code': 'MOVING_CHARGES_&_MAGNETISM',
      'topicsList': [
        {'id': 't_phy_18_1', 'name': '18.1 Biot-Savart Law & Magnetic Field of Wire/Loop', 'code': 'TOPIC_BIOT_SAVART', 'status': 'Active'},
        {'id': 't_phy_18_2', 'name': '18.2 Ampere\'s Law, Solenoid & Toroid Fields', 'code': 'TOPIC_AMPERE_LAW', 'status': 'Active'},
        {'id': 't_phy_18_3', 'name': '18.3 Magnetic Lorentz Force & Motion in Combined Fields', 'code': 'TOPIC_LORENTZ_FORCE', 'status': 'Active'},
        {'id': 't_phy_18_4', 'name': '18.4 Torque on Current Loop & Moving Coil Galvanometer', 'code': 'TOPIC_GALVANOMETER', 'status': 'Active'},
      ],
    },
    {
      'name': '19. Magnetism & Matter',
      'code': 'MAGNETISM_&_MATTER',
      'topicsList': [
        {'id': 't_phy_19_1', 'name': '19.1 Magnetic Dipole, Bar Magnet & Magnetic Field', 'code': 'TOPIC_BAR_MAGNET', 'status': 'Active'},
        {'id': 't_phy_19_2', 'name': '19.2 Earth\'s Magnetism & Magnetic Elements', 'code': 'TOPIC_EARTH_MAGNETISM', 'status': 'Active'},
        {'id': 't_phy_19_3', 'name': '19.3 Magnetic Properties (Dia, Para & Ferromagnetism)', 'code': 'TOPIC_MAGNETIC_PROPERTIES', 'status': 'Active'},
      ],
    },
    {
      'name': '20. EMI (Electromagnetic Induction)',
      'code': 'EMI_(ELECTROMAGNETIC_INDUCTION)',
      'topicsList': [
        {'id': 't_phy_20_1', 'name': '20.1 Faraday\'s Experiments & Lenz\'s Law', 'code': 'TOPIC_FARADAY_LENZ', 'status': 'Active'},
        {'id': 't_phy_20_2', 'name': '20.2 Motional EMF & Induced Electric Fields', 'code': 'TOPIC_MOTIONAL_EMF', 'status': 'Active'},
        {'id': 't_phy_20_3', 'name': '20.3 Eddy Currents & Applications', 'code': 'TOPIC_EDDY_CURRENTS', 'status': 'Active'},
        {'id': 't_phy_20_4', 'name': '20.4 Self & Mutual Inductance, AC Generator', 'code': 'TOPIC_INDUCTANCE', 'status': 'Active'},
      ],
    },
    {
      'name': '21. AC (Alternating Current)',
      'code': 'AC_(ALTERNATING_CURRENT)',
      'topicsList': [
        {'id': 't_phy_21_1', 'name': '21.1 Peak, Average & RMS Values of AC', 'code': 'TOPIC_AC_RMS', 'status': 'Active'},
        {'id': 't_phy_21_2', 'name': '21.2 AC Circuits (Resistive, Inductive & Capacitive)', 'code': 'TOPIC_RLC_CIRCUITS', 'status': 'Active'},
        {'id': 't_phy_21_3', 'name': '21.3 Series LCR Circuit, Resonance & Quality Factor', 'code': 'TOPIC_LCR_RESONANCE', 'status': 'Active'},
        {'id': 't_phy_21_4', 'name': '21.4 Power in AC Circuits, Wattless Current & Transformers', 'code': 'TOPIC_TRANSFORMER', 'status': 'Active'},
      ],
    },
    {
      'name': '22. EM Waves (Electromagnetic Waves)',
      'code': 'EM_WAVES_(ELECTROMAGNETIC_WAVES)',
      'topicsList': [
        {'id': 't_phy_22_1', 'name': '22.1 Displacement Current & Maxwell\'s Equations', 'code': 'TOPIC_DISPLACEMENT_CURR', 'status': 'Active'},
        {'id': 't_phy_22_2', 'name': '22.2 Nature & Propagation of EM Waves', 'code': 'TOPIC_EM_PROPAGATION', 'status': 'Active'},
        {'id': 't_phy_22_3', 'name': '22.3 Electromagnetic Spectrum & Industrial/Medical Uses', 'code': 'TOPIC_EM_SPECTRUM', 'status': 'Active'},
      ],
    },
    {
      'name': '23. Ray Optics',
      'code': 'RAY_OPTICS',
      'topicsList': [
        {'id': 't_phy_23_1', 'name': '23.1 Reflection at Spherical Mirrors & Mirror Formula', 'code': 'TOPIC_MIRRORS', 'status': 'Active'},
        {'id': 't_phy_23_2', 'name': '23.2 Refraction, Snell\'s Law & Total Internal Reflection', 'code': 'TOPIC_REFRACTION_TIR', 'status': 'Active'},
        {'id': 't_phy_23_3', 'name': '23.3 Refraction at Spherical Surfaces & Lens Maker\'s Formula', 'code': 'TOPIC_LENSES', 'status': 'Active'},
        {'id': 't_phy_23_4', 'name': '23.4 Optical Instruments (Compound Microscope & Telescope)', 'code': 'TOPIC_OPTICAL_INSTRUMENTS', 'status': 'Active'},
      ],
    },
    {
      'name': '24. Wave Optics',
      'code': 'WAVE_OPTICS',
      'topicsList': [
        {'id': 't_phy_24_1', 'name': '24.1 Wavefronts & Huygens\' Principle', 'code': 'TOPIC_HUYGENS', 'status': 'Active'},
        {'id': 't_phy_24_2', 'name': '24.2 Interference of Light & Young\'s Double Slit Experiment', 'code': 'TOPIC_YDSE', 'status': 'Active'},
        {'id': 't_phy_24_3', 'name': '24.3 Single Slit Diffraction & Resolving Power', 'code': 'TOPIC_DIFFRACTION', 'status': 'Active'},
        {'id': 't_phy_24_4', 'name': '24.4 Polarisation of Light & Brewster\'s Law', 'code': 'TOPIC_POLARISATION', 'status': 'Active'},
      ],
    },
    {
      'name': '25. Dual Nature of Radiation & Matter',
      'code': 'DUAL_NATURE_OF_RADIATION_&_MATTER',
      'topicsList': [
        {'id': 't_phy_25_1', 'name': '25.1 Photoelectric Effect & Einstein\'s Equation', 'code': 'TOPIC_PHOTOELECTRIC', 'status': 'Active'},
        {'id': 't_phy_25_2', 'name': '25.2 Cut-off Potential & Threshold Frequency', 'code': 'TOPIC_STOPPING_POTENTIAL', 'status': 'Active'},
        {'id': 't_phy_25_3', 'name': '25.3 de Broglie Wavelength & Matter Waves', 'code': 'TOPIC_DE_BROGLIE', 'status': 'Active'},
      ],
    },
    {
      'name': '26. Atoms',
      'code': 'ATOMS',
      'topicsList': [
        {'id': 't_phy_26_1', 'name': '26.1 Alpha-Particle Scattering & Rutherford Atom Model', 'code': 'TOPIC_RUTHERFORD', 'status': 'Active'},
        {'id': 't_phy_26_2', 'name': '26.2 Bohr Model of Hydrogen Atom & Postulates', 'code': 'TOPIC_BOHR_MODEL', 'status': 'Active'},
        {'id': 't_phy_26_3', 'name': '26.3 Energy Levels & Hydrogen Spectral Series', 'code': 'TOPIC_HYDROGEN_SPECTRUM', 'status': 'Active'},
      ],
    },
    {
      'name': '27. Nuclei',
      'code': 'NUCLEI',
      'topicsList': [
        {'id': 't_phy_27_1', 'name': '27.1 Nuclear Composition, Size & Nuclear Density', 'code': 'TOPIC_NUCLEAR_SIZE', 'status': 'Active'},
        {'id': 't_phy_27_2', 'name': '27.2 Mass Defect & Binding Energy Curve', 'code': 'TOPIC_BINDING_ENERGY', 'status': 'Active'},
        {'id': 't_phy_27_3', 'name': '27.3 Nuclear Fission & Controlled Nuclear Fusion', 'code': 'TOPIC_FISSION_FUSION', 'status': 'Active'},
      ],
    },
    {
      'name': '28. Semiconductors',
      'code': 'SEMICONDUCTORS',
      'topicsList': [
        {'id': 't_phy_28_1', 'name': '28.1 Energy Bands in Solids & Semiconductor Types (p & n)', 'code': 'TOPIC_ENERGY_BANDS', 'status': 'Active'},
        {'id': 't_phy_28_2', 'name': '28.2 Semiconductor Diode: Forward & Reverse Characteristics', 'code': 'TOPIC_DIODE_IV', 'status': 'Active'},
        {'id': 't_phy_28_3', 'name': '28.3 Diode as Rectifier (Half-Wave & Full-Wave Rectification)', 'code': 'TOPIC_RECTIFIER', 'status': 'Active'},
        {'id': 't_phy_28_4', 'name': '28.4 Optoelectronic Junction Devices (LED, Photodiode, Solar Cell)', 'code': 'TOPIC_OPTOELECTRONIC', 'status': 'Active'},
      ],
    },
  ];

  static final List<Map<String, dynamic>> neetChemistryChapters = [
    {
      'name': '1. Mole Concept',
      'code': 'MOLE_CONCEPT',
      'topicsList': [
        {'id': 't_ch_1_1', 'name': '1.1 Stoichiometry & Laws of Chemical Combinations', 'code': 'TOPIC_STOICHIOMETRY', 'status': 'Active'},
        {'id': 't_ch_1_2', 'name': '1.2 Mole Concept, Molar Mass & Percentage Composition', 'code': 'TOPIC_MOLAR_MASS', 'status': 'Active'},
        {'id': 't_ch_1_3', 'name': '1.3 Empirical & Molecular Formulae', 'code': 'TOPIC_EMPIRICAL_FORMULA', 'status': 'Active'},
        {'id': 't_ch_1_4', 'name': '1.4 Concentration Terms (Molarity, Molality, Mole Fraction)', 'code': 'TOPIC_CONCENTRATIONS', 'status': 'Active'},
      ],
    },
    {
      'name': '2. Structure of Atom',
      'code': 'STRUCTURE_OF_ATOM',
      'topicsList': [
        {'id': 't_ch_2_1', 'name': '2.1 Bohr\'s Model & Hydrogen Line Spectrum', 'code': 'TOPIC_BOHR_CHEM', 'status': 'Active'},
        {'id': 't_ch_2_2', 'name': '2.2 de Broglie & Heisenberg Uncertainty Principle', 'code': 'TOPIC_HEISENBERG', 'status': 'Active'},
        {'id': 't_ch_2_3', 'name': '2.3 Quantum Numbers & Orbital Shapes', 'code': 'TOPIC_QUANTUM_NUMBERS', 'status': 'Active'},
        {'id': 't_ch_2_4', 'name': '2.4 Aufbau, Pauli & Hund\'s Rules of Electronic Configuration', 'code': 'TOPIC_ELECTRONIC_CONFIG', 'status': 'Active'},
      ],
    },
    {
      'name': '3. Periodic Table',
      'code': 'PERIODIC_TABLE',
      'topicsList': [
        {'id': 't_ch_3_1', 'name': '3.1 Modern Periodic Law & Long Form of Periodic Table', 'code': 'TOPIC_MODERN_PERIODIC', 'status': 'Active'},
        {'id': 't_ch_3_2', 'name': '3.2 Periodic Trends in Atomic & Ionic Radii', 'code': 'TOPIC_ATOMIC_RADII', 'status': 'Active'},
        {'id': 't_ch_3_3', 'name': '3.3 Ionization Enthalpy & Electron Gain Enthalpy', 'code': 'TOPIC_IONIZATION_ENERGY', 'status': 'Active'},
        {'id': 't_ch_3_4', 'name': '3.4 Electronegativity & Valence/Oxidation States', 'code': 'TOPIC_ELECTRONEGATIVITY', 'status': 'Active'},
      ],
    },
    {
      'name': '4. Chemical Bonding',
      'code': 'CHEMICAL_BONDING',
      'topicsList': [
        {'id': 't_ch_4_1', 'name': '4.1 Ionic & Covalent Bonds, Octet Rule Exceptions', 'code': 'TOPIC_COVALENT_BOND', 'status': 'Active'},
        {'id': 't_ch_4_2', 'name': '4.2 VSEPR Theory & Molecular Geometry', 'code': 'TOPIC_VSEPR', 'status': 'Active'},
        {'id': 't_ch_4_3', 'name': '4.3 Valence Bond Theory & Hybridisation (sp, sp2, sp3, sp3d)', 'code': 'TOPIC_HYBRIDISATION', 'status': 'Active'},
        {'id': 't_ch_4_4', 'name': '4.4 Molecular Orbital Theory (MOT) & Hydrogen Bonding', 'code': 'TOPIC_MOT', 'status': 'Active'},
      ],
    },
    {
      'name': '5. Thermodynamics',
      'code': 'THERMODYNAMICS',
      'topicsList': [
        {'id': 't_ch_5_1', 'name': '5.1 First Law of Thermodynamics, Enthalpy & Internal Energy', 'code': 'TOPIC_ENTHALPY', 'status': 'Active'},
        {'id': 't_ch_5_2', 'name': '5.2 Hess\'s Law of Constant Heat Summation', 'code': 'TOPIC_HESS_LAW', 'status': 'Active'},
        {'id': 't_ch_5_3', 'name': '5.3 Entropy & Second Law of Thermodynamics', 'code': 'TOPIC_ENTROPY', 'status': 'Active'},
        {'id': 't_ch_5_4', 'name': '5.4 Gibbs Free Energy & Criterion of Spontaneity', 'code': 'TOPIC_GIBBS_ENERGY', 'status': 'Active'},
      ],
    },
    {
      'name': '6. Chemical Equilibrium',
      'code': 'CHEMICAL_EQUILIBRIUM',
      'topicsList': [
        {'id': 't_ch_6_1', 'name': '6.1 Law of Mass Action & Equilibrium Constants (Kc, Kp)', 'code': 'TOPIC_KP_KC', 'status': 'Active'},
        {'id': 't_ch_6_2', 'name': '6.2 Le Chatelier\'s Principle & Factors Affecting Equilibrium', 'code': 'TOPIC_LE_CHATELIER', 'status': 'Active'},
      ],
    },
    {
      'name': '7. Ionic Equilibrium',
      'code': 'IONIC_EQUILIBRIUM',
      'topicsList': [
        {'id': 't_ch_7_1', 'name': '7.1 Theories of Acids & Bases (Arrhenius, Bronsted, Lewis)', 'code': 'TOPIC_ACIDS_BASES', 'status': 'Active'},
        {'id': 't_ch_7_2', 'name': '7.2 Ionisation of Water & pH Scale Calculations', 'code': 'TOPIC_PH_SCALE', 'status': 'Active'},
        {'id': 't_ch_7_3', 'name': '7.3 Common Ion Effect & Buffer Solutions', 'code': 'TOPIC_BUFFERS', 'status': 'Active'},
        {'id': 't_ch_7_4', 'name': '7.4 Solubility Product (Ksp) & Salt Hydrolysis', 'code': 'TOPIC_KSP', 'status': 'Active'},
      ],
    },
    {
      'name': '8. Redox Reactions',
      'code': 'REDOX_REACTIONS',
      'topicsList': [
        {'id': 't_ch_8_1', 'name': '8.1 Oxidation Number Concept & Balancing Redox Reactions', 'code': 'TOPIC_OXIDATION_NUMBER', 'status': 'Active'},
        {'id': 't_ch_8_2', 'name': '8.2 Electrochemical Series & Standard Reduction Potentials', 'code': 'TOPIC_REDOX_SERIES', 'status': 'Active'},
      ],
    },
    {
      'name': '9. P-Block',
      'code': 'P-BLOCK',
      'topicsList': [
        {'id': 't_ch_9_1', 'name': '9.1 Group 13 & 14 Elements: Anomalous Properties & Trends', 'code': 'TOPIC_GRP_13_14', 'status': 'Active'},
        {'id': 't_ch_9_2', 'name': '9.2 Group 15, 16, 17 & 18 Elements: Allotropes & Oxoacids', 'code': 'TOPIC_GRP_15_18', 'status': 'Active'},
      ],
    },
    {
      'name': '10. GOC (General Organic Chemistry)',
      'code': 'GOC_(GENERAL_ORGANIC_CHEMISTRY)',
      'topicsList': [
        {'id': 't_ch_10_1', 'name': '10.1 IUPAC Nomenclature of Organic Compounds', 'code': 'TOPIC_IUPAC', 'status': 'Active'},
        {'id': 't_ch_10_2', 'name': '10.2 Electronic Displacement Effects (Inductive, Resonance, Hyperconjugation)', 'code': 'TOPIC_ELECTRONIC_EFFECTS', 'status': 'Active'},
        {'id': 't_ch_10_3', 'name': '10.3 Reactive Intermediates (Carbocations, Carbanions, Free Radicals)', 'code': 'TOPIC_INTERMEDIATES', 'status': 'Active'},
        {'id': 't_ch_10_4', 'name': '10.4 Isomerism: Structural & Stereoisomerism', 'code': 'TOPIC_ISOMERISM', 'status': 'Active'},
      ],
    },
    {
      'name': '11. Hydrocarbons',
      'code': 'HYDROCARBONS',
      'topicsList': [
        {'id': 't_ch_11_1', 'name': '11.1 Alkanes: Preparation, Halogenation & Conformations', 'code': 'TOPIC_ALKANES', 'status': 'Active'},
        {'id': 't_ch_11_2', 'name': '11.2 Alkenes: Addition Reactions (Markovnikov & Anti-Markovnikov)', 'code': 'TOPIC_ALKENES', 'status': 'Active'},
        {'id': 't_ch_11_3', 'name': '11.3 Alkynes: Acidity, Ozonolysis & Polymerization', 'code': 'TOPIC_ALKYNES', 'status': 'Active'},
        {'id': 't_ch_11_4', 'name': '11.4 Aromatic Hydrocarbons: Huckel\'s Rule & Electrophilic Substitution', 'code': 'TOPIC_AROMATIC', 'status': 'Active'},
      ],
    },
    {
      'name': '12. Solutions',
      'code': 'SOLUTIONS',
      'topicsList': [
        {'id': 't_ch_12_1', 'name': '12.1 Henry\'s Law & Raoult\'s Law for Volatile Solutes', 'code': 'TOPIC_RAOULT_LAW', 'status': 'Active'},
        {'id': 't_ch_12_2', 'name': '12.2 Ideal & Non-Ideal Solutions with Azeotropes', 'code': 'TOPIC_IDEAL_SOLUTIONS', 'status': 'Active'},
        {'id': 't_ch_12_3', 'name': '12.3 Colligative Properties (RLVP, Elevation in BP, Depression in FP, Osmotic Pressure)', 'code': 'TOPIC_COLLIGATIVE', 'status': 'Active'},
        {'id': 't_ch_12_4', 'name': '12.4 Abnormal Molar Mass & Van\'t Hoff Factor (i)', 'code': 'TOPIC_VANT_HOFF', 'status': 'Active'},
      ],
    },
    {
      'name': '13. Electrochemistry',
      'code': 'ELECTROCHEMISTRY',
      'topicsList': [
        {'id': 't_ch_13_1', 'name': '13.1 Galvanic Cells, Cell Potential & Nernst Equation', 'code': 'TOPIC_NERNST_EQUATION', 'status': 'Active'},
        {'id': 't_ch_13_2', 'name': '13.2 Conductance in Electrolytic Solutions & Kohlrausch\'s Law', 'code': 'TOPIC_KOHLRAUSCH', 'status': 'Active'},
        {'id': 't_ch_13_3', 'name': '13.3 Electrolysis & Faraday\'s Laws of Electrolysis', 'code': 'TOPIC_FARADAY_LAWS', 'status': 'Active'},
        {'id': 't_ch_13_4', 'name': '13.4 Commercial Batteries, Fuel Cells & Corrosion', 'code': 'TOPIC_BATTERIES', 'status': 'Active'},
      ],
    },
    {
      'name': '14. Chemical Kinetics',
      'code': 'CHEMICAL_KINETICS',
      'topicsList': [
        {'id': 't_ch_14_1', 'name': '14.1 Rate of Reaction, Rate Law & Order/Molecularity', 'code': 'TOPIC_RATE_LAW', 'status': 'Active'},
        {'id': 't_ch_14_2', 'name': '14.2 Integrated Rate Equations (Zero & First Order) & Half-Life', 'code': 'TOPIC_INTEGRATED_RATE', 'status': 'Active'},
        {'id': 't_ch_14_3', 'name': '14.3 Temperature Dependence of Rate & Arrhenius Equation', 'code': 'TOPIC_ARRHENIUS', 'status': 'Active'},
        {'id': 't_ch_14_4', 'name': '14.4 Collision Theory of Chemical Reactions', 'code': 'TOPIC_COLLISION_THEORY', 'status': 'Active'},
      ],
    },
    {
      'name': '16. d & f Block',
      'code': 'D_&_F_BLOCK',
      'topicsList': [
        {'id': 't_ch_16_1', 'name': '16.1 General Properties of Transition Elements (3d series)', 'code': 'TOPIC_TRANSITION_ELEMENTS', 'status': 'Active'},
        {'id': 't_ch_16_2', 'name': '16.2 Important Compounds: K2Cr2O7 & KMnO4', 'code': 'TOPIC_KMNO4_K2CR2O7', 'status': 'Active'},
        {'id': 't_ch_16_3', 'name': '16.3 Lanthanoids, Lanthanoid Contraction & Actinoids', 'code': 'TOPIC_LANTHANOIDS', 'status': 'Active'},
      ],
    },
    {
      'name': '17. Coordination Compounds',
      'code': 'COORDINATION_COMPOUNDS',
      'topicsList': [
        {'id': 't_ch_17_1', 'name': '17.1 Werner\'s Theory & IUPAC Nomenclature of Complexes', 'code': 'TOPIC_WERNER_IUPAC', 'status': 'Active'},
        {'id': 't_ch_17_2', 'name': '17.2 Isomerism in Coordination Compounds', 'code': 'TOPIC_COORD_ISOMERISM', 'status': 'Active'},
        {'id': 't_ch_17_3', 'name': '17.3 Valence Bond Theory & Crystal Field Theory (CFT)', 'code': 'TOPIC_CFT', 'status': 'Active'},
        {'id': 't_ch_17_4', 'name': '17.4 Stability of Complexes & Biological Applications', 'code': 'TOPIC_COORD_APPLICATIONS', 'status': 'Active'},
      ],
    },
    {
      'name': '18. Haloalkanes & Haloarenes',
      'code': 'HALOALKANES_&_HALOARENES',
      'topicsList': [
        {'id': 't_ch_18_1', 'name': '18.1 Methods of Preparation of Haloalkanes & Haloarenes', 'code': 'TOPIC_HALO_PREP', 'status': 'Active'},
        {'id': 't_ch_18_2', 'name': '18.2 Nucleophilic Substitution Mechanisms (SN1 & SN2)', 'code': 'TOPIC_SN1_SN2', 'status': 'Active'},
        {'id': 't_ch_18_3', 'name': '18.3 Elimination Reactions (Saytzeff Rule) & Polyhalogen Compounds', 'code': 'TOPIC_ELIMINATION', 'status': 'Active'},
      ],
    },
    {
      'name': '19. Alcohols, Phenols & Ethers',
      'code': 'ALCOHOLS,_PHENOLS_&_ETHERS',
      'topicsList': [
        {'id': 't_ch_19_1', 'name': '19.1 Alcohols: Preparation, Properties & Lucas/Victor Meyer Tests', 'code': 'TOPIC_ALCOHOLS', 'status': 'Active'},
        {'id': 't_ch_19_2', 'name': '19.2 Phenols: Acidity, Electrophilic Substitution & Reimer-Tiemann', 'code': 'TOPIC_PHENOLS', 'status': 'Active'},
        {'id': 't_ch_19_3', 'name': '19.3 Ethers: Williamson Synthesis & Cleavage by HI', 'code': 'TOPIC_ETHERS', 'status': 'Active'},
      ],
    },
    {
      'name': '20. Aldehydes, Ketones & Carboxylic Acids',
      'code': 'ALDEHYDES,_KETONES_&_CARBOXYLIC_ACIDS',
      'topicsList': [
        {'id': 't_ch_20_1', 'name': '20.1 Carbonyl Group & Nucleophilic Addition Reactions', 'code': 'TOPIC_CARBONYL_ADDITION', 'status': 'Active'},
        {'id': 't_ch_20_2', 'name': '20.2 Aldol Condensation, Cannizzaro & Clemmensen Reactions', 'code': 'TOPIC_NAMED_REACTIONS', 'status': 'Active'},
        {'id': 't_ch_20_3', 'name': '20.3 Carboxylic Acids: Acidity, Hell-Volhard-Zelinsky Reaction', 'code': 'TOPIC_CARBOXYLIC_ACIDS', 'status': 'Active'},
      ],
    },
    {
      'name': '21. Amines',
      'code': 'AMINES',
      'topicsList': [
        {'id': 't_ch_21_1', 'name': '21.1 Structure, Classification & Basicity of Amines', 'code': 'TOPIC_AMINES_BASICITY', 'status': 'Active'},
        {'id': 't_ch_21_2', 'name': '21.2 Chemical Reactions: Carbylamine & Hinsberg Test', 'code': 'TOPIC_HINSBERG', 'status': 'Active'},
        {'id': 't_ch_21_3', 'name': '21.3 Diazonium Salts: Preparation & Synthetic Transformations', 'code': 'TOPIC_DIAZONIUM', 'status': 'Active'},
      ],
    },
    {
      'name': '22. Biomolecules',
      'code': 'BIOMOLECULES',
      'topicsList': [
        {'id': 't_ch_22_1', 'name': '22.1 Carbohydrates: Monosaccharides, Glucose Structure & Mutarotation', 'code': 'TOPIC_CARBOHYDRATES', 'status': 'Active'},
        {'id': 't_ch_22_2', 'name': '22.2 Proteins: Amino Acids, Peptide Bond & Protein Denaturation', 'code': 'TOPIC_PROTEINS', 'status': 'Active'},
        {'id': 't_ch_22_3', 'name': '22.3 Nucleic Acids (DNA & RNA) & Vitamins', 'code': 'TOPIC_NUCLEIC_ACIDS', 'status': 'Active'},
      ],
    },
    {
      'name': '23. Salt Analysis',
      'code': 'SALT_ANALYSIS',
      'topicsList': [
        {'id': 't_ch_23_1', 'name': '23.1 Detection of Cations (Group I to VI)', 'code': 'TOPIC_CATIONS', 'status': 'Active'},
        {'id': 't_ch_23_2', 'name': '23.2 Detection of Anions (Dilute & Concentrated H2SO4 Tests)', 'code': 'TOPIC_ANIONS', 'status': 'Active'},
      ],
    },
  ];

  static final List<Map<String, dynamic>> neetBiologyChapters = [
    {
      'name': '1. Living World',
      'code': 'LIVING_WORLD',
      'topicsList': [
        {'id': 't_bio_1_1', 'name': '1.1 What is Living? Biodiversity & Need for Classification', 'code': 'TOPIC_WHAT_IS_LIVING', 'status': 'Active'},
        {'id': 't_bio_1_2', 'name': '1.2 Taxonomy, Systematics & Binomial Nomenclature', 'code': 'TOPIC_BINOMIAL_NOMENCLATURE', 'status': 'Active'},
        {'id': 't_bio_1_3', 'name': '1.3 Taxonomic Categories & Taxonomic Hierarchy', 'code': 'TOPIC_TAXONOMIC_HIERARCHY', 'status': 'Active'},
      ],
    },
    {
      'name': '2. Biological Classification',
      'code': 'BIOLOGICAL_CLASSIFICATION',
      'topicsList': [
        {'id': 't_bio_2_1', 'name': '2.1 Five Kingdom Classification & Kingdom Monera', 'code': 'TOPIC_MONERA', 'status': 'Active'},
        {'id': 't_bio_2_2', 'name': '2.2 Kingdom Protista & Kingdom Fungi', 'code': 'TOPIC_PROTISTA_FUNGI', 'status': 'Active'},
        {'id': 't_bio_2_3', 'name': '2.3 Viruses, Viroids, Prions & Lichens', 'code': 'TOPIC_VIRUSES_PRIONS', 'status': 'Active'},
      ],
    },
    {
      'name': '3. Plant Kingdom',
      'code': 'PLANT_KINGDOM',
      'topicsList': [
        {'id': 't_bio_3_1', 'name': '3.1 Algae: Classification, Pigments & Economic Importance', 'code': 'TOPIC_ALGAE', 'status': 'Active'},
        {'id': 't_bio_3_2', 'name': '3.2 Bryophytes & Pteridophytes (Life Cycles & Features)', 'code': 'TOPIC_BRYOPHYTES', 'status': 'Active'},
        {'id': 't_bio_3_3', 'name': '3.3 Gymnosperms & Angiosperms', 'code': 'TOPIC_GYMNOSPERMS', 'status': 'Active'},
      ],
    },
    {
      'name': '4. Animal Kingdom',
      'code': 'ANIMAL_KINGDOM',
      'topicsList': [
        {'id': 't_bio_4_1', 'name': '4.1 Basis of Classification (Symmetry, Coelom, Germ Layers)', 'code': 'TOPIC_ANIMAL_BASIS', 'status': 'Active'},
        {'id': 't_bio_4_2', 'name': '4.2 Non-Chordates: Porifera to Echinodermata & Hemichordata', 'code': 'TOPIC_NON_CHORDATES', 'status': 'Active'},
        {'id': 't_bio_4_3', 'name': '4.3 Phylum Chordata: Cyclostomes to Mammals', 'code': 'TOPIC_CHORDATES', 'status': 'Active'},
      ],
    },
    {
      'name': '5. Morphology of Flowering Plants',
      'code': 'MORPHOLOGY_OF_FLOWERING_PLANTS',
      'topicsList': [
        {'id': 't_bio_5_1', 'name': '5.1 Morphology of Root, Stem & Leaf (Modifications)', 'code': 'TOPIC_ROOT_STEM_LEAF', 'status': 'Active'},
        {'id': 't_bio_5_2', 'name': '5.2 Inflorescence, Flower Structure & Aestivation', 'code': 'TOPIC_FLOWER_STRUCTURE', 'status': 'Active'},
        {'id': 't_bio_5_3', 'name': '5.3 Fruit, Seed & Description of Angiospermic Families', 'code': 'TOPIC_PLANT_FAMILIES', 'status': 'Active'},
      ],
    },
    {
      'name': '6. Anatomy of Flowering Plants',
      'code': 'ANATOMY_OF_FLOWERING_PLANTS',
      'topicsList': [
        {'id': 't_bio_6_1', 'name': '6.1 Meristematic & Permanent Tissues', 'code': 'TOPIC_PLANT_TISSUES', 'status': 'Active'},
        {'id': 't_bio_6_2', 'name': '6.2 Tissue System & Internal Anatomy of Dicot/Monocot Root & Stem', 'code': 'TOPIC_INTERNAL_ANATOMY', 'status': 'Active'},
        {'id': 't_bio_6_3', 'name': '6.3 Anatomy of Dicot & Monocot Leaves', 'code': 'TOPIC_LEAF_ANATOMY', 'status': 'Active'},
      ],
    },
    {
      'name': '7. Structural Organisation in Animals',
      'code': 'STRUCTURAL_ORGANISATION_IN_ANIMALS',
      'topicsList': [
        {'id': 't_bio_7_1', 'name': '7.1 Animal Tissues: Epithelial, Connective, Muscular & Neural', 'code': 'TOPIC_ANIMAL_TISSUES', 'status': 'Active'},
        {'id': 't_bio_7_2', 'name': '7.2 Morphology, Anatomy & Organ Systems of Frog', 'code': 'TOPIC_FROG_ANATOMY', 'status': 'Active'},
      ],
    },
    {
      'name': '8. Cell: The Unit of Life',
      'code': 'CELL:_THE_UNIT_OF_LIFE',
      'topicsList': [
        {'id': 't_bio_8_1', 'name': '8.1 Cell Theory & Overview of Prokaryotic vs Eukaryotic Cell', 'code': 'TOPIC_CELL_THEORY', 'status': 'Active'},
        {'id': 't_bio_8_2', 'name': '8.2 Cell Membrane (Fluid Mosaic Model) & Cell Wall', 'code': 'TOPIC_CELL_MEMBRANE', 'status': 'Active'},
        {'id': 't_bio_8_3', 'name': '8.3 Endomembrane System: ER, Golgi, Lysosomes & Vacuoles', 'code': 'TOPIC_ENDOMEMBRANE', 'status': 'Active'},
        {'id': 't_bio_8_4', 'name': '8.4 Mitochondria, Plastids, Ribosomes & Nucleus', 'code': 'TOPIC_ORGANELLES', 'status': 'Active'},
      ],
    },
    {
      'name': '9. Biomolecules',
      'code': 'BIOMOLECULES',
      'topicsList': [
        {'id': 't_bio_9_1', 'name': '9.1 Chemical Analysis of Living Tissues & Primary/Secondary Metabolites', 'code': 'TOPIC_METABOLITES', 'status': 'Active'},
        {'id': 't_bio_9_2', 'name': '9.2 Biomacromolecules: Proteins, Polysaccharides & Lipids', 'code': 'TOPIC_BIOMACROMOLECULES', 'status': 'Active'},
        {'id': 't_bio_9_3', 'name': '9.3 Structure of Nucleic Acids & Nature of Bond Linking Monomers', 'code': 'TOPIC_NUCLEIC_BONDS', 'status': 'Active'},
        {'id': 't_bio_9_4', 'name': '9.4 Enzymes: Classification, Properties, Activation Energy & Inhibition', 'code': 'TOPIC_ENZYMES', 'status': 'Active'},
      ],
    },
    {
      'name': '10. Cell Cycle and Cell Division',
      'code': 'CELL_CYCLE_AND_CELL_DIVISION',
      'topicsList': [
        {'id': 't_bio_10_1', 'name': '10.1 Cell Cycle Phases (G1, S, G2 & M Phase)', 'code': 'TOPIC_CELL_CYCLE_PHASES', 'status': 'Active'},
        {'id': 't_bio_10_2', 'name': '10.2 Mitosis & Cytokinesis', 'code': 'TOPIC_MITOSIS', 'status': 'Active'},
        {'id': 't_bio_10_3', 'name': '10.3 Meiosis I & Meiosis II, Crossing Over & Significance', 'code': 'TOPIC_MEIOSIS', 'status': 'Active'},
      ],
    },
    {
      'name': '11. Photosynthesis in Plants',
      'code': 'PHOTOSYNTHESIS_IN_PLANTS',
      'topicsList': [
        {'id': 't_bio_11_1', 'name': '11.1 Photosynthetic Pigments & Light Reaction (Z-scheme)', 'code': 'TOPIC_LIGHT_REACTION', 'status': 'Active'},
        {'id': 't_bio_11_2', 'name': '11.2 Cyclic & Non-Cyclic Photophosphorylation', 'code': 'TOPIC_PHOTOPHOSPHORYLATION', 'status': 'Active'},
        {'id': 't_bio_11_3', 'name': '11.3 Calvin Cycle (C3 Pathway), C4 Pathway & Photorespiration', 'code': 'TOPIC_DARK_REACTION', 'status': 'Active'},
        {'id': 't_bio_11_4', 'name': '11.4 Factors Affecting Photosynthesis (Blackman\'s Law)', 'code': 'TOPIC_PHOTOSYN_FACTORS', 'status': 'Active'},
      ],
    },
    {
      'name': '12. Respiration in Plants',
      'code': 'RESPIRATION_IN_PLANTS',
      'topicsList': [
        {'id': 't_bio_12_1', 'name': '12.1 Cellular Respiration Overview & Glycolysis (EMP Pathway)', 'code': 'TOPIC_GLYCOLYSIS', 'status': 'Active'},
        {'id': 't_bio_12_2', 'name': '12.2 Fermentation (Anaerobic Respiration)', 'code': 'TOPIC_FERMENTATION', 'status': 'Active'},
        {'id': 't_bio_12_3', 'name': '12.3 Krebs Cycle (TCA Cycle) & Electron Transport System (ETS)', 'code': 'TOPIC_KREBS_ETS', 'status': 'Active'},
        {'id': 't_bio_12_4', 'name': '12.4 Amphibolic Pathway & Respiratory Quotient (RQ)', 'code': 'TOPIC_RQ', 'status': 'Active'},
      ],
    },
    {
      'name': '13. Plant Growth and Development (PGR)',
      'code': 'PLANT_GROWTH_AND_DEVELOPMENT_(PGR)',
      'topicsList': [
        {'id': 't_bio_13_1', 'name': '13.1 Phases of Growth, Growth Rates & Differentiation', 'code': 'TOPIC_GROWTH_PHASES', 'status': 'Active'},
        {'id': 't_bio_13_2', 'name': '13.2 Plant Growth Regulators: Auxins, Gibberellins & Cytokinins', 'code': 'TOPIC_PGR_PROMOTERS', 'status': 'Active'},
        {'id': 't_bio_13_3', 'name': '13.3 Plant Growth Inhibitors: Ethylene & Abscisic Acid (ABA)', 'code': 'TOPIC_PGR_INHIBITORS', 'status': 'Active'},
      ],
    },
    {
      'name': '14. Breathing and Exchange of Gases',
      'code': 'BREATHING_AND_EXCHANGE_OF_GASES',
      'topicsList': [
        {'id': 't_bio_14_1', 'name': '14.1 Respiratory Organs & Human Respiratory System', 'code': 'TOPIC_RESP_ORGANS', 'status': 'Active'},
        {'id': 't_bio_14_2', 'name': '14.2 Mechanism of Breathing & Respiratory Volumes/Capacities', 'code': 'TOPIC_BREATHING_MECH', 'status': 'Active'},
        {'id': 't_bio_14_3', 'name': '14.3 Exchange & Transport of Gases (O2 & CO2 Transport)', 'code': 'TOPIC_GAS_EXCHANGE', 'status': 'Active'},
        {'id': 't_bio_14_4', 'name': '14.4 Regulation of Respiration & Respiratory Disorders', 'code': 'TOPIC_RESP_DISORDERS', 'status': 'Active'},
      ],
    },
    {
      'name': '15. Body Fluids and Circulation',
      'code': 'BODY_FLUIDS_AND_CIRCULATION',
      'topicsList': [
        {'id': 't_bio_15_1', 'name': '15.1 Blood Composition, Formed Elements & Blood Groups (ABO, Rh)', 'code': 'TOPIC_BLOOD_GROUPS', 'status': 'Active'},
        {'id': 't_bio_15_2', 'name': '15.2 Coagulation of Blood & Lymph (Tissue Fluid)', 'code': 'TOPIC_COAGULATION', 'status': 'Active'},
        {'id': 't_bio_15_3', 'name': '15.3 Human Heart Anatomy, Cardiac Cycle & ECG', 'code': 'TOPIC_CARDIAC_CYCLE', 'status': 'Active'},
        {'id': 't_bio_15_4', 'name': '15.4 Double Circulation & Disorders of Circulatory System', 'code': 'TOPIC_CIRC_DISORDERS', 'status': 'Active'},
      ],
    },
    {
      'name': '16. Excretory Products and Their Elimination',
      'code': 'EXCRETORY_PRODUCTS_AND_THEIR_ELIMINATION',
      'topicsList': [
        {'id': 't_bio_16_1', 'name': '16.1 Modes of Excretion (Ammonotelism, Ureotelism, Uricotelism)', 'code': 'TOPIC_EXCRETION_MODES', 'status': 'Active'},
        {'id': 't_bio_16_2', 'name': '16.2 Human Excretory System & Nephron Structure', 'code': 'TOPIC_NEPHRON_STRUCTURE', 'status': 'Active'},
        {'id': 't_bio_16_3', 'name': '16.3 Urine Formation (Filtration, Reabsorption & Secretion)', 'code': 'TOPIC_URINE_FORMATION', 'status': 'Active'},
        {'id': 't_bio_16_4', 'name': '16.4 Regulation of Kidney Function (RAAS, ANF, ADH) & Disorders', 'code': 'TOPIC_RAAS_REGULATION', 'status': 'Active'},
      ],
    },
    {
      'name': '17. Locomotion and Movement',
      'code': 'LOCOMOTION_AND_MOVEMENT',
      'topicsList': [
        {'id': 't_bio_17_1', 'name': '17.1 Types of Movement & Structure of Skeletal Muscle', 'code': 'TOPIC_MUSCLE_STRUCTURE', 'status': 'Active'},
        {'id': 't_bio_17_2', 'name': '17.2 Mechanism of Muscle Contraction (Sliding Filament Theory)', 'code': 'TOPIC_SLIDING_FILAMENT', 'status': 'Active'},
        {'id': 't_bio_17_3', 'name': '17.3 Human Skeletal System: Axial & Appendicular Skeleton', 'code': 'TOPIC_SKELETAL_SYSTEM', 'status': 'Active'},
        {'id': 't_bio_17_4', 'name': '17.4 Types of Joints & Disorders of Musculoskeletal System', 'code': 'TOPIC_JOINTS_DISORDERS', 'status': 'Active'},
      ],
    },
    {
      'name': '18. Neural Control and Coordination',
      'code': 'NEURAL_CONTROL_AND_COORDINATION',
      'topicsList': [
        {'id': 't_bio_18_1', 'name': '18.1 Neuron as Structural Unit & Nerve Impulse Conduction', 'code': 'TOPIC_IMPULSE_CONDUCTION', 'status': 'Active'},
        {'id': 't_bio_18_2', 'name': '18.2 Synaptic Transmission (Electrical & Chemical Synapses)', 'code': 'TOPIC_SYNAPSE', 'status': 'Active'},
        {'id': 't_bio_18_3', 'name': '18.3 Central Nervous System (Forebrain, Midbrain & Hindbrain)', 'code': 'TOPIC_HUMAN_BRAIN', 'status': 'Active'},
      ],
    },
    {
      'name': '19. Chemical Coordination and Integration',
      'code': 'CHEMICAL_COORDINATION_AND_INTEGRATION',
      'topicsList': [
        {'id': 't_bio_19_1', 'name': '19.1 Endocrine Glands & Hypothalamus/Pituitary Hormones', 'code': 'TOPIC_PITUITARY_HORMONES', 'status': 'Active'},
        {'id': 't_bio_19_2', 'name': '19.2 Thyroid, Parathyroid, Adrenal, Pancreas & Gonads', 'code': 'TOPIC_ENDOCRINE_GLANDS', 'status': 'Active'},
        {'id': 't_bio_19_3', 'name': '19.3 Mechanism of Hormone Action (Peptide & Steroid Hormones)', 'code': 'TOPIC_HORMONE_ACTION', 'status': 'Active'},
      ],
    },
    {
      'name': '20. Sexual Reproduction in Flowering Plants',
      'code': 'SEXUAL_REPRODUCTION_IN_FLOWERING_PLANTS',
      'topicsList': [
        {'id': 't_bio_20_1', 'name': '20.1 Flower Structure, Microsporogenesis & Pollen Grain', 'code': 'TOPIC_MICROSPOROGENESIS', 'status': 'Active'},
        {'id': 't_bio_20_2', 'name': '20.2 Megasporogenesis & Embryo Sac Development', 'code': 'TOPIC_MEGASPOROGENESIS', 'status': 'Active'},
        {'id': 't_bio_20_3', 'name': '20.3 Pollination (Agents, Outbreeding Devices, Pollen-Pistil Interaction)', 'code': 'TOPIC_POLLINATION', 'status': 'Active'},
        {'id': 't_bio_20_4', 'name': '20.4 Double Fertilization, Endosperm, Embryo & Seed Formation', 'code': 'TOPIC_DOUBLE_FERTILIZATION', 'status': 'Active'},
      ],
    },
    {
      'name': '21. Human Reproduction',
      'code': 'HUMAN_REPRODUCTION',
      'topicsList': [
        {'id': 't_bio_21_1', 'name': '21.1 Male Reproductive System & Spermatogenesis', 'code': 'TOPIC_MALE_REPRODUCTION', 'status': 'Active'},
        {'id': 't_bio_21_2', 'name': '21.2 Female Reproductive System & Oogenesis', 'code': 'TOPIC_FEMALE_REPRODUCTION', 'status': 'Active'},
        {'id': 't_bio_21_3', 'name': '21.3 Menstrual Cycle & Hormonal Control', 'code': 'TOPIC_MENSTRUAL_CYCLE', 'status': 'Active'},
        {'id': 't_bio_21_4', 'name': '21.4 Fertilization, Cleavage, Blastocyst Implantation & Parturition', 'code': 'TOPIC_FERTILIZATION_IMPLANTATION', 'status': 'Active'},
      ],
    },
    {
      'name': '22. Reproductive Health',
      'code': 'REPRODUCTIVE_HEALTH',
      'topicsList': [
        {'id': 't_bio_22_1', 'name': '22.1 Population Stabilization & Contraceptive Methods', 'code': 'TOPIC_CONTRACEPTION', 'status': 'Active'},
        {'id': 't_bio_22_2', 'name': '22.2 Medical Termination of Pregnancy (MTP) & STIs', 'code': 'TOPIC_MTP_STIS', 'status': 'Active'},
        {'id': 't_bio_22_3', 'name': '22.3 Infertility & Assisted Reproductive Technologies (ART, IVF, ICSI)', 'code': 'TOPIC_ART_IVF', 'status': 'Active'},
      ],
    },
    {
      'name': '23. Principles of Inheritance and Variation',
      'code': 'PRINCIPLES_OF_INHERITANCE_AND_VARIATION',
      'topicsList': [
        {'id': 't_bio_23_1', 'name': '23.1 Mendel\'s Laws of Inheritance (Monohybrid & Dihybrid Crosses)', 'code': 'TOPIC_MENDEL_LAWS', 'status': 'Active'},
        {'id': 't_bio_23_2', 'name': '23.2 Incomplete Dominance, Co-dominance & Multiple Alleles', 'code': 'TOPIC_NON_MENDELIAN', 'status': 'Active'},
        {'id': 't_bio_23_3', 'name': '23.3 Chromosomal Theory of Inheritance & Linkage/Recombination', 'code': 'TOPIC_LINKAGE', 'status': 'Active'},
        {'id': 't_bio_23_4', 'name': '23.4 Sex Determination, Pedigree Analysis & Genetic Disorders', 'code': 'TOPIC_GENETIC_DISORDERS', 'status': 'Active'},
      ],
    },
    {
      'name': '24. Molecular Basis of Inheritance',
      'code': 'MOLECULAR_BASIS_OF_INHERITANCE',
      'topicsList': [
        {'id': 't_bio_24_1', 'name': '24.1 DNA as Genetic Material (Griffith, Avery, Hershey-Chase)', 'code': 'TOPIC_DNA_STRUCTURE', 'status': 'Active'},
        {'id': 't_bio_24_2', 'name': '24.2 Semiconservative DNA Replication & Meselson-Stahl Experiment', 'code': 'TOPIC_DNA_REPLICATION', 'status': 'Active'},
        {'id': 't_bio_24_3', 'name': '24.3 Transcription, Genetic Code & Translation (Protein Synthesis)', 'code': 'TOPIC_TRANSCRIPTION_TRANSLATION', 'status': 'Active'},
        {'id': 't_bio_24_4', 'name': '24.4 Regulation of Gene Expression (Lac Operon) & Human Genome Project (HGP)', 'code': 'TOPIC_LAC_OPERON_HGP', 'status': 'Active'},
      ],
    },
    {
      'name': '25. Evolution',
      'code': 'EVOLUTION',
      'topicsList': [
        {'id': 't_bio_25_1', 'name': '25.1 Origin of Life & Evidences for Evolution (Homology & Analogy)', 'code': 'TOPIC_ORIGIN_OF_LIFE', 'status': 'Active'},
        {'id': 't_bio_25_2', 'name': '25.2 Darwinian Theory, Natural Selection & Adaptive Radiation', 'code': 'TOPIC_DARWINISM', 'status': 'Active'},
        {'id': 't_bio_25_3', 'name': '25.3 Modern Synthetic Theory, Hardy-Weinberg Principle & Human Evolution', 'code': 'TOPIC_HARDY_WEINBERG', 'status': 'Active'},
      ],
    },
    {
      'name': '26. Human Health and Disease',
      'code': 'HUMAN_HEALTH_AND_DISEASE',
      'topicsList': [
        {'id': 't_bio_26_1', 'name': '26.1 Common Infectious Diseases in Humans (Pathogens & Transmission)', 'code': 'TOPIC_INFECTIOUS_DISEASES', 'status': 'Active'},
        {'id': 't_bio_26_2', 'name': '26.2 Immunity: Innate & Acquired Immunity, Antibodies & Vaccination', 'code': 'TOPIC_IMMUNITY', 'status': 'Active'},
        {'id': 't_bio_26_3', 'name': '26.3 AIDS & Cancer (Mechanisms, Diagnosis & Treatment)', 'code': 'TOPIC_AIDS_CANCER', 'status': 'Active'},
        {'id': 't_bio_26_4', 'name': '26.4 Drugs & Alcohol Abuse', 'code': 'TOPIC_DRUG_ABUSE', 'status': 'Active'},
      ],
    },
    {
      'name': '27. Microbes in Human Welfare',
      'code': 'MICROBES_IN_HUMAN_WELFARE',
      'topicsList': [
        {'id': 't_bio_27_1', 'name': '27.1 Microbes in Household Food Processing & Industrial Products', 'code': 'TOPIC_MICROBES_HOUSEHOLD', 'status': 'Active'},
        {'id': 't_bio_27_2', 'name': '27.2 Microbes in Sewage Treatment & Biogas Production', 'code': 'TOPIC_SEWAGE_BIOGAS', 'status': 'Active'},
        {'id': 't_bio_27_3', 'name': '27.3 Microbes as Biocontrol Agents & Biofertilizers', 'code': 'TOPIC_BIOFERTILIZERS', 'status': 'Active'},
      ],
    },
    {
      'name': '28. Biotechnology: Principles and Processes',
      'code': 'BIOTECHNOLOGY:_PRINCIPLES_AND_PROCESSES',
      'topicsList': [
        {'id': 't_bio_28_1', 'name': '28.1 Tools of Recombinant DNA Technology (Restriction Enzymes, Ligases, Vectors)', 'code': 'TOPIC_RDNA_TOOLS', 'status': 'Active'},
        {'id': 't_bio_28_2', 'name': '28.2 Processes of Recombinant DNA Technology & PCR Amplification', 'code': 'TOPIC_PCR_PROCESSES', 'status': 'Active'},
        {'id': 't_bio_28_3', 'name': '28.3 Bioreactors & Downstream Processing', 'code': 'TOPIC_BIOREACTORS', 'status': 'Active'},
      ],
    },
    {
      'name': '29. Biotechnology and its Applications',
      'code': 'BIOTECHNOLOGY_AND_ITS_APPLICATIONS',
      'topicsList': [
        {'id': 't_bio_29_1', 'name': '29.1 Applications in Agriculture (Bt Cotton, RNA Interference)', 'code': 'TOPIC_BIOTECH_AGRICULTURE', 'status': 'Active'},
        {'id': 't_bio_29_2', 'name': '29.2 Applications in Medicine (Genetically Engineered Insulin, Gene Therapy, Molecular Diagnosis)', 'code': 'TOPIC_BIOTECH_MEDICINE', 'status': 'Active'},
        {'id': 't_bio_29_3', 'name': '29.3 Transgenic Animals, Biosafety Issues & Biopiracy', 'code': 'TOPIC_TRANSGENIC_ANIMALS', 'status': 'Active'},
      ],
    },
    {
      'name': '30. Organisms and Populations',
      'code': 'ORGANISMS_AND_POPULATIONS',
      'topicsList': [
        {'id': 't_bio_30_1', 'name': '30.1 Organism and Its Environment, Adaptations to Abiotic Factors', 'code': 'TOPIC_ADAPTATIONS', 'status': 'Active'},
        {'id': 't_bio_30_2', 'name': '30.2 Population Attributes, Growth Models (Exponential & Logistic)', 'code': 'TOPIC_POPULATION_GROWTH', 'status': 'Active'},
        {'id': 't_bio_30_3', 'name': '30.3 Population Interactions (Mutualism, Competition, Predation, Parasitism)', 'code': 'TOPIC_POPULATION_INTERACTIONS', 'status': 'Active'},
      ],
    },
    {
      'name': '31. Ecosystem',
      'code': 'ECOSYSTEM',
      'topicsList': [
        {'id': 't_bio_31_1', 'name': '31.1 Ecosystem Structure, Productivity & Decomposition', 'code': 'TOPIC_PRODUCTIVITY', 'status': 'Active'},
        {'id': 't_bio_31_2', 'name': '31.2 Energy Flow, Food Chains & Ecological Pyramids', 'code': 'TOPIC_ENERGY_FLOW', 'status': 'Active'},
      ],
    },
    {
      'name': '32. Biodiversity and Conservation',
      'code': 'BIODIVERSITY_AND_CONSERVATION',
      'topicsList': [
        {'id': 't_bio_32_1', 'name': '32.1 Patterns of Biodiversity & Latitudinal Gradients', 'code': 'TOPIC_BIODIVERSITY_PATTERNS', 'status': 'Active'},
        {'id': 't_bio_32_2', 'name': '32.2 Loss of Biodiversity & The Evil Quartet', 'code': 'TOPIC_BIODIVERSITY_LOSS', 'status': 'Active'},
        {'id': 't_bio_32_3', 'name': '32.3 In-situ & Ex-situ Conservation Strategies, National Parks & Hotspots', 'code': 'TOPIC_CONSERVATION_STRATEGIES', 'status': 'Active'},
      ],
    },
  ];

  static final List<Map<String, dynamic>> jeeMathChapters = [
    {
      'name': '1. Sets, Relations & Functions',
      'code': 'MATH_SETS',
      'topicsList': [
        {'id': 't_math_1_1', 'name': '1.1 Sets & Relations', 'code': 'TOPIC_SETS', 'status': 'Active'},
        {'id': 't_math_1_2', 'name': '1.2 Functions & Domain/Range', 'code': 'TOPIC_FUNCTIONS', 'status': 'Active'},
      ],
    },
    {
      'name': '2. Complex Numbers & Quadratic Equations',
      'code': 'MATH_COMPLEX',
      'topicsList': [
        {'id': 't_math_2_1', 'name': '2.1 Complex Numbers Algebra & Argand Plane', 'code': 'TOPIC_COMPLEX', 'status': 'Active'},
        {'id': 't_math_2_2', 'name': '2.2 Quadratic Equations & Location of Roots', 'code': 'TOPIC_QUADRATIC', 'status': 'Active'},
      ],
    },
  ];
}
