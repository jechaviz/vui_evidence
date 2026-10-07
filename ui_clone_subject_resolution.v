module vui_evidence

pub struct UiCloneSubjectInput {
pub:
	visual_reference_profile  string
	functional_target_profile string
	target_profile            string
	target_app_profile        string
	clone_intent              string
}

pub struct UiCloneSubjectResolution {
pub:
	visual_profile              string
	functional_profile          string
	target_profile              string
	target_app_profile          string
	clone_intent                string
	mode                        string
	cross_profile               bool
	ready                       bool
	blocker                     string
	visual_source               string
	functional_source           string
	functional_subject_explicit bool
	visual_reference_subject    string
	functional_target_subject   string
	visual_reference_role       string
	functional_target_role      string
	reasoning_rule              string
	blind_risk                  string
}

pub fn ui_clone_subject_resolution(input UiCloneSubjectInput) UiCloneSubjectResolution {
	intent := normalized_clone_value(input.clone_intent)
	mode := if intent in ['functional_ui_clone', 'functional_clone', 'ui_clone'] {
		'semantic_functional_clone'
	} else {
		'pixel_reference_clone'
	}
	visual := ui_clone_subject_visual_profile(input)
	functional := ui_clone_subject_functional_profile(input, visual)
	ready := ui_clone_subject_ready(mode, functional)
	return UiCloneSubjectResolution{
		visual_profile:              visual
		functional_profile:          functional
		target_profile:              canonical_clone_profile(input.target_profile)
		target_app_profile:          canonical_clone_profile(input.target_app_profile)
		clone_intent:                intent
		mode:                        mode
		cross_profile:               visual != '' && functional != '' && visual != functional
		ready:                       ready
		blocker:                     ui_clone_subject_blocker(mode, functional, ready)
		visual_source:               ui_clone_subject_visual_source(input)
		functional_source:           ui_clone_subject_functional_source(input, visual)
		functional_subject_explicit: ui_clone_subject_functional_explicit(input)
		visual_reference_subject:    ui_clone_functional_clone_subject(visual)
		functional_target_subject:   ui_clone_functional_clone_subject(functional)
		visual_reference_role:       ui_clone_subject_visual_role(mode, visual, functional)
		functional_target_role:      ui_clone_subject_functional_role(mode, functional)
		reasoning_rule:              ui_clone_subject_reasoning_rule(mode, visual, functional, ui_clone_subject_functional_source(input,
			visual))
		blind_risk:                  ui_clone_subject_blind_risk(mode, input, visual, functional)
	}
}

fn ui_clone_subject_visual_profile(input UiCloneSubjectInput) string {
	if canonical_clone_profile(input.visual_reference_profile) != '' {
		return canonical_clone_profile(input.visual_reference_profile)
	}
	if canonical_clone_profile(input.target_profile) != '' {
		return canonical_clone_profile(input.target_profile)
	}
	return canonical_clone_profile(input.target_app_profile)
}

fn ui_clone_subject_functional_profile(input UiCloneSubjectInput, visual string) string {
	functional := canonical_clone_profile(input.functional_target_profile)
	if functional != '' {
		return functional
	}
	target_app := canonical_clone_profile(input.target_app_profile)
	if target_app != '' {
		return target_app
	}
	target := canonical_clone_profile(input.target_profile)
	if target != '' && canonical_clone_profile(input.visual_reference_profile) != ''
		&& target != visual {
		return target
	}
	return visual
}

fn ui_clone_subject_visual_source(input UiCloneSubjectInput) string {
	if canonical_clone_profile(input.visual_reference_profile) != '' {
		return 'visual_reference_profile'
	}
	if canonical_clone_profile(input.target_profile) != '' {
		return 'target_profile'
	}
	if canonical_clone_profile(input.target_app_profile) != '' {
		return 'target_app_profile'
	}
	return 'missing'
}

fn ui_clone_subject_functional_source(input UiCloneSubjectInput, visual string) string {
	if canonical_clone_profile(input.functional_target_profile) != '' {
		return 'functional_target_profile'
	}
	if canonical_clone_profile(input.target_app_profile) != '' {
		return 'target_app_profile'
	}
	target := canonical_clone_profile(input.target_profile)
	if target != '' && canonical_clone_profile(input.visual_reference_profile) != ''
		&& target != visual {
		return 'target_profile'
	}
	if visual != '' {
		return 'visual_reference_default'
	}
	return 'missing'
}

fn ui_clone_subject_functional_explicit(input UiCloneSubjectInput) bool {
	return canonical_clone_profile(input.functional_target_profile) != ''
		|| canonical_clone_profile(input.target_app_profile) != ''
}

fn ui_clone_subject_ready(mode string, functional string) bool {
	if mode != 'semantic_functional_clone' {
		return true
	}
	return ui_clone_known_functional_profile(functional)
}

fn ui_clone_subject_blocker(mode string, functional string, ready bool) string {
	if mode == 'semantic_functional_clone' && !ready {
		if functional == '' {
			return 'functional_clone_subject_missing'
		}
		return 'functional_clone_target_profile_unknown'
	}
	return ''
}

fn ui_clone_subject_visual_role(mode string, visual string, functional string) string {
	if mode != 'semantic_functional_clone' {
		return 'visual pixels and text are the comparison subject'
	}
	if visual != '' && functional != '' && visual != functional {
		return 'visual reference supplies geometry, landmarks, and affordance loci only'
	}
	return 'visual reference supplies stable anchors for the same functional subject'
}

fn ui_clone_subject_functional_role(mode string, functional string) string {
	if mode != 'semantic_functional_clone' {
		return 'no functional subject is required for visual-only QA'
	}
	if functional == '' {
		return 'functional subject must be declared or inferred before behavior can be certified'
	}
	return 'functional subject owns commands, state deltas, runtime data masks, and certification'
}

fn ui_clone_subject_reasoning_rule(mode string, visual string, functional string,
	functional_source string) string {
	if mode != 'semantic_functional_clone' {
		return 'visual-only comparisons may certify pixels, not behavior'
	}
	if functional_source == 'missing' {
		return 'blocked until the functional subject is declared'
	}
	if visual != '' && functional != '' && visual != functional {
		return 'compare the visual subject as layout/locus while probing the functional subject for behavior'
	}
	return 'compare stable anchors, mask runtime text, and require behavior receipts for the declared subject'
}

fn ui_clone_subject_blind_risk(mode string, input UiCloneSubjectInput, visual string,
	functional string) string {
	if mode != 'semantic_functional_clone' {
		return ''
	}
	if functional == '' {
		return 'functional_subject_missing'
	}
	if !ui_clone_subject_functional_explicit(input) && visual == functional {
		return 'functional_subject_defaulted_to_visual_reference'
	}
	return ''
}
