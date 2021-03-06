class LessonsController < ApplicationController
  before_action :set_lesson, only: [:show, :edit, :update, :destroy, :confirm, :lesson_rating, :add_rating]
  before_action :authenticate_user!
  skip_before_action :need_rating, only: [:lesson_rating, :add_rating]
  def index
    redirect_to upcoming_lessons_path
  end

  def lesson_rating
    @skill = @lesson.skill
  end

  def my_upcoming_lessons
    my_lessons_as_teacher = current_user.lessons_as_teacher.select {|l| l.start_time > DateTime.now}
    my_lessons_as_student = current_user.lessons_as_student.select {|l| l.start_time > DateTime.now}
    @my_unconfirmed_lessons_as_teacher = my_lessons_as_teacher.select {|l| l.confirmed_at == nil}
    @my_unconfirmed_lessons_as_student = my_lessons_as_student.select {|l| l.confirmed_at == nil}
    @my_confirmed_lessons_as_teacher = my_lessons_as_teacher.select {|l| l.confirmed_at.class == ActiveSupport::TimeWithZone}
    @my_confirmed_lessons_as_student = my_lessons_as_student.select {|l| l.confirmed_at.class == ActiveSupport::TimeWithZone}
  end

  def my_completed_lessons
    @my_completed_lessons_as_teacher = current_user.lessons_as_teacher.select {|l| l.start_time < DateTime.now}
    @my_completed_lessons_as_student = current_user.lessons_as_student.select {|l| l.start_time < DateTime.now}
  end

  def show
  end

  def new
    @lesson = Lesson.new
    @skill = Skill.find_by(id: params[:skill])
  end


  def confirm
    if @lesson.teacher != current_user
      redirect_to @lesson, notice: 'You can only confirm lessons you teach.'
    else
      @lesson.confirmed_at = DateTime.now
      @lesson.save
      UserMailer.confirm_lesson(@lesson).deliver_now!
      redirect_to @lesson, notice: 'Lesson was successfully confirmed.'
    end
  end

  def add_rating
    if current_user == @lesson.teacher && @lesson.teacher_rating_student == nil
      @lesson.teacher_rating_student = params[:score].to_i
      @lesson.teacher_reviewing_student = lesson_params[:review]
      @lesson.save
      @lesson.student.points -= @lesson.hours
      @lesson.student.save
      @lesson.teacher.points += @lesson.hours
      @lesson.teacher.save

      UserMailer.completed_lesson_notice(@lesson).deliver_now!
      redirect_to upcoming_lessons_path, notice: 'Lesson was successfully completed.'
    elsif current_user == @lesson.teacher
      @lesson.teacher_rating_student = params[:score].to_i
      @lesson.save
      redirect_to upcoming_lessons_path, notice: 'Rating was successfully changed.'
    elsif current_user == @lesson.student && @lesson.student_rating_teacher == nil
      @lesson.student_rating_teacher = params[:score].to_i
      @lesson.student_reviewing_teacher = lesson_params[:review]
      @lesson.save

      UserMailer.completed_lesson_notice(@lesson).deliver_now!
      redirect_to upcoming_lessons_path, notice: 'Lesson was successfully completed.'
    elsif current_user == @lesson.student
      @lesson.student_rating_teacher = params[:score].to_i
      @lesson.save
      redirect_to upcoming_lessons_path, notice: 'Rating was successfully changed.'
    end
  end


  def create
    @lesson = Lesson.new(lesson_params)
    @skill = Skill.find_by(id: params[:skill])
    @lesson.skill = @skill
    @lesson.teacher = @lesson.skill.teacher
    @lesson.student = current_user
    @lesson.requested_at = DateTime.now
    respond_to do |format|
      if @lesson.student.points < @lesson.hours
        format.html { redirect_to my_skills_path, notice: "You don't have enough points!  Try teaching to earn more" }
      elsif @lesson.teacher == current_user
        format.html { redirect_to @skill, notice: 'You cannot learn your own skill.' }
      elsif @lesson.start_time < DateTime.now
        format.html { redirect_to @skill, notice: 'You cannot schedule a lesson in the past.' }
      elsif @lesson.save
        format.html { redirect_to @lesson, notice: 'Lesson was successfully requested.' }
        format.json { render :show, status: :created, location: @lesson }
      else
        format.html { render :new }
        format.json { render json: @lesson.errors, status: :unprocessable_entity }
      end
    end
  end


  def update
    respond_to do |format|
      if @lesson.start_time + @lesson.hours*60*60 < DateTime.now
       format.html { redirect_to @lesson, notice: "Sorry, you can't edit past lessons!" }
      elsif @lesson.student_id != current_user.id
       format.html { redirect_to @lesson, notice: 'Sorry, you may only edit your own lessons!' }
      elsif @lesson.update(lesson_params)
        @lesson.confirmed_at = nil
        @lesson.save
        format.html { redirect_to @lesson, notice: 'Lesson was successfully updated.' }
        format.json { render :show, status: :ok, location: @lesson }
      else
        format.html { render :edit }
        format.json { render json: @lesson.errors, status: :unprocessable_entity }
      end
    end
  end


  def destroy
    @lesson.destroy
    respond_to do |format|
      format.html { redirect_to upcoming_lessons_path, notice: 'Lesson was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    def set_lesson
      @lesson = Lesson.find(params[:id])
    end

    def lesson_params
      whitelisted = params.require(:lesson).permit(:skill, :teacher, :student, :teacher_rating_student, :student_rating_teacher, :start_time, :hours, :requested_at, :confirmed_at, :teacher_reviewing_student, :student_reviewing_teacher, :rating, :review)
      whitelisted.merge(teacher_id: current_user.id.to_i)
    end
end
